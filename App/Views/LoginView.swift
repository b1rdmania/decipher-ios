import SwiftUI

/// Privy email one-time-code login. Two steps in one screen: enter email, then
/// enter the 6-digit code.
struct LoginView: View {
    @Bindable var auth: AuthModel

    @State private var email = ""
    @State private var code = ""
    @FocusState private var focused: Field?

    private enum Field { case email, code }

    private var awaitingCode: Bool { auth.phase == .awaitingCode }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header

                if awaitingCode {
                    codeStep
                } else {
                    emailStep
                }

                if let message = auth.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                if !AppConfig.isPrivyConfigured {
                    Label("Add your Privy app and client IDs in AppConfig.swift to enable sign-in.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear { focused = .email }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Decipher")
                .font(.largeTitle.bold())
            Text(awaitingCode
                 ? "Enter the code we sent to \(auth.pendingEmail)."
                 : "Sign in with your email to start speaking.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 48)
        .padding(.bottom, 8)
    }

    private var emailStep: some View {
        VStack(spacing: 16) {
            TextField("you@example.com", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused, equals: .email)
                .submitLabel(.send)
                .onSubmit(submitEmail)
                .padding()
                .background(.thinMaterial, in: .rect(cornerRadius: 12))

            Button(action: submitEmail) {
                Label("Send code", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(email.isEmpty || auth.isSubmitting)
            .overlay { if auth.isSubmitting { ProgressView() } }
        }
    }

    private var codeStep: some View {
        VStack(spacing: 16) {
            TextField("123456", text: $code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2.monospacedDigit())
                .focused($focused, equals: .code)
                .padding()
                .background(.thinMaterial, in: .rect(cornerRadius: 12))

            Button(action: submitCode) {
                Label("Verify", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(code.isEmpty || auth.isSubmitting)
            .overlay { if auth.isSubmitting { ProgressView() } }

            Button("Use a different email") {
                code = ""
                auth.startOver()
                focused = .email
            }
            .font(.footnote)
            .padding(.top, 4)
        }
        .onAppear { focused = .code }
    }

    private func submitEmail() {
        guard !email.isEmpty else { return }
        Task { await auth.sendCode(to: email) }
    }

    private func submitCode() {
        guard !code.isEmpty else { return }
        Task { await auth.verifyCode(code) }
    }
}
