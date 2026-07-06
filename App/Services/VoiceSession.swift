import Foundation
import LiveKit

/// Drives one LiveKit voice conversation with the Decipher agent using the
/// push-to-talk protocol from CLAUDE.md:
///
/// 1. connect → publish mic, immediately mute, send `mic_ready`
/// 2. press   → unmute mic, send `ptt_press`
/// 3. release → mute mic, send `ptt_release`
///
/// The remote agent joins and speaks first; its audio is auto-played by the SDK.
@MainActor
@Observable
final class VoiceSession {
    enum Status: Equatable {
        case connecting
        case ready          // mic published + muted, waiting for the user
        case ended
        case failed(String)
    }

    private(set) var status: Status = .connecting
    /// True while the user is holding the talk button (mic unmuted).
    private(set) var isTalking = false
    /// True while the remote agent is the active speaker.
    private(set) var isAgentSpeaking = false

    private let sessionId: String
    private let connection: SessionStart.LiveKitConnection
    private let api: DecipherAPI

    private let room: Room
    private var micTrackSid: String?
    private var startedAt: Date?
    private var didEnd = false

    init(sessionId: String, connection: SessionStart.LiveKitConnection, api: DecipherAPI) {
        self.sessionId = sessionId
        self.connection = connection
        self.api = api
        self.room = Room()
        // All stored properties are set, so `self` is now usable as a delegate.
        room.add(delegate: self)
    }

    // MARK: - Lifecycle

    func connect() async {
        status = .connecting
        do {
            try await room.connect(url: connection.url, token: connection.token)
            startedAt = Date()

            // Publish the mic (first enable creates + publishes the track)…
            let publication = try await room.localParticipant.setMicrophone(enabled: true)
            micTrackSid = publication?.sid.stringValue
            // …then immediately mute it — muting keeps the publication and sid.
            try await room.localParticipant.setMicrophone(enabled: false)

            status = .ready
            if let sid = micTrackSid {
                await send(.micReady(trackSid: sid))
            }
        } catch {
            status = .failed("Couldn't join the voice session. Please try again.")
        }
    }

    /// Ends the session: reports elapsed time to the backend and disconnects.
    /// Safe to call more than once (hangup + background can both fire).
    func end() async {
        guard !didEnd else { return }
        didEnd = true

        let duration = startedAt.map { Int(Date().timeIntervalSince($0)) } ?? 0
        await room.disconnect()
        status = .ended

        // Best-effort; a failed end report shouldn't surface as an error here.
        try? await api.endSession(sessionId: sessionId, durationSec: duration)
    }

    // MARK: - Push to talk

    func beginTalking() async {
        guard status == .ready, !isTalking else { return }
        isTalking = true
        do {
            try await room.localParticipant.setMicrophone(enabled: true) // unmute
            await send(.pttPress)
        } catch {
            isTalking = false
        }
    }

    func endTalking() async {
        guard isTalking else { return }
        isTalking = false
        try? await room.localParticipant.setMicrophone(enabled: false)   // mute
        await send(.pttRelease)
    }

    // MARK: - Data channel

    private func send(_ message: PTTMessage) async {
        try? await room.localParticipant.publish(
            data: message.encoded(),
            options: DataPublishOptions(reliable: true)
        )
    }
}

// MARK: - RoomDelegate

extension VoiceSession: RoomDelegate {
    nonisolated func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) {
        let agentSpeaking = participants.contains { $0 is RemoteParticipant }
        Task { @MainActor [weak self] in
            self?.isAgentSpeaking = agentSpeaking
        }
    }

    nonisolated func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        Task { @MainActor [weak self] in
            guard let self, self.status != .ended else { return }
            if error != nil {
                self.status = .failed("The voice session disconnected. Please try again.")
            }
        }
    }
}
