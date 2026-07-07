import SwiftUI

/// The live voice loop: shows connection/agent state and a hold-to-talk button.
struct VoiceView: View {
    let voice: VoiceSession
    let onHangUp: () -> Void

    @State private var isPressing = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            statusArea
            Spacer()
            talkButton
                .padding(.bottom, 48)
            hangUpButton
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressing)
        // End the session if the app leaves the foreground.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { onHangUp() }
        }
    }

    // MARK: - Status

    private var statusArea: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(.tint.opacity(voice.isAgentSpeaking ? 0.25 : 0.12))
                    .frame(width: 160, height: 160)
                    .scaleEffect(voice.isAgentSpeaking ? 1.08 : 1)
                    .animation(.bouncy, value: voice.isAgentSpeaking)
                Image(systemName: "waveform")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.tint)
                    .symbolEffect(.variableColor.iterative, isActive: voice.isAgentSpeaking)
            }

            Text(statusTitle)
                .font(.title3.weight(.semibold))
                .contentTransition(.opacity)
            Text(statusSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var statusTitle: String {
        switch voice.status {
        case .connecting: return "Connecting…"
        case .ready: return voice.isTalking ? "Listening to you" : (voice.isAgentSpeaking ? "Speaking" : "Your turn")
        case .ended: return "Session ended"
        case .failed(let message): return message
        }
    }

    private var statusSubtitle: String {
        switch voice.status {
        case .connecting: return "Joining the conversation."
        case .ready: return voice.isTalking ? "Release to let the agent respond." : "Hold the button to talk."
        case .ended: return "Thanks for practicing."
        case .failed: return "Tap end and try again."
        }
    }

    // MARK: - Controls

    private var talkButton: some View {
        let enabled = voice.status == .ready
        return Circle()
            .fill(isPressing ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.85)))
            .frame(width: 128, height: 128)
            .overlay {
                Image(systemName: isPressing ? "mic.fill" : "mic")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isPressing ? 1.1 : 1)
            .animation(.snappy(duration: 0.2), value: isPressing)
            .opacity(enabled ? 1 : 0.4)
            .accessibilityLabel("Hold to talk")
            .accessibilityAddTraits(.isButton)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard enabled, !isPressing else { return }
                        isPressing = true
                        Task { await voice.beginTalking() }
                    }
                    .onEnded { _ in
                        guard isPressing else { return }
                        isPressing = false
                        Task { await voice.endTalking() }
                    }
            )
    }

    private var hangUpButton: some View {
        Button(role: .destructive, action: onHangUp) {
            Label("End session", systemImage: "phone.down.fill")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.red)
    }
}
