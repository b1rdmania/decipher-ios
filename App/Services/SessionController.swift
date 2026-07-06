import Foundation

/// Owns the start-session → voice-loop lifecycle for a single scenario. Bridges
/// the API client and the live `VoiceSession`.
@MainActor
@Observable
final class SessionController {
    enum State: Equatable {
        case idle
        case starting
        case active
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var voice: VoiceSession?

    let scenario: ScenarioType
    private let api: DecipherAPI

    init(auth: AuthModel, scenario: ScenarioType) {
        self.scenario = scenario
        self.api = DecipherAPI(tokenProvider: { try await auth.accessToken() })
    }

    func start() async {
        guard state != .starting, state != .active else { return }
        state = .starting
        do {
            let start = try await api.startSession(scenario: scenario)
            let session = VoiceSession(
                sessionId: start.session.id,
                connection: start.livekit,
                api: api
            )
            voice = session
            state = .active
            await session.connect()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't start the session. Please try again."
            state = .error(message)
        }
    }

    func stop() async {
        await voice?.end()
        voice = nil
        state = .idle
    }
}
