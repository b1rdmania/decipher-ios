import SwiftUI

/// Signed-in home: start the Phase 0 voice session (scenario: Ordering Coffee),
/// or drop into the live voice loop once it's active.
struct SessionHomeView: View {
    let auth: AuthModel

    // Phase 0 targets a single scenario per CLAUDE.md.
    @State private var controller: SessionController

    init(auth: AuthModel) {
        self.auth = auth
        _controller = State(wrappedValue: SessionController(auth: auth, scenario: .orderingCoffee))
    }

    var body: some View {
        Group {
            if controller.state == .active, let voice = controller.voice {
                VoiceView(voice: voice) {
                    Task { await controller.stop() }
                }
            } else {
                launcher
            }
        }
        .animation(.smooth, value: controller.state)
    }

    private var launcher: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 60)

                Image(systemName: controller.scenario.symbol)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 120, height: 120)
                    .background(.thinMaterial, in: .circle)

                VStack(spacing: 6) {
                    Text(controller.scenario.title)
                        .font(.title.bold())
                    Text("Practice a real conversation with the Decipher voice agent. Hold to talk, release to listen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                if case .error(let message) = controller.state {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: { Task { await controller.start() } }) {
                    Group {
                        if controller.state == .starting {
                            ProgressView().tint(.white)
                        } else {
                            Label("Start Session", systemImage: "mic.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(controller.state == .starting)
                .padding(.horizontal)

                Spacer(minLength: 20)

                Button("Sign out") { Task { await auth.signOut() } }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
