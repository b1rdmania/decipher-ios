import Foundation
import PrivySDK

/// Wraps the Privy SDK: initialization, the email one-time-code login flow, and
/// fresh access tokens for the Decipher API. There is exactly one instance for
/// the app lifetime — `PrivySdk.initialize` must never be called twice.
@Observable
@MainActor
final class AuthModel {
    /// Coarse UI state derived from Privy's auth state.
    enum Phase: Equatable {
        case loading            // SDK not ready yet
        case signedOut
        case awaitingCode       // code sent, waiting for the user to enter it
        case signedIn
    }

    private(set) var phase: Phase = .loading
    private(set) var errorMessage: String?
    private(set) var isSubmitting = false

    /// Email the code was last sent to, so the verify step can reference it.
    private(set) var pendingEmail: String = ""

    private let privy: Privy

    init() {
        let config = PrivyConfig(
            appId: AppConfig.privyAppID,
            appClientId: AppConfig.privyClientID,
            loggingConfig: .init(logLevel: .verbose)
        )
        privy = PrivySdk.initialize(config: config)
        observeAuthState()
    }

    // MARK: - Auth state

    private func observeAuthState() {
        // Reflect the current snapshot, then follow the live stream.
        apply(privy.authState)
        Task { [weak self] in
            guard let stream = self?.privy.authStateStream else { return }
            for await state in stream {
                self?.apply(state)
            }
        }
    }

    private func apply(_ state: AuthState) {
        switch state {
        case .notReady:
            phase = .loading
        case .unauthenticated, .authenticatedUnverified:
            // Stay on the code screen if we're mid-flow; otherwise signed out.
            if phase != .awaitingCode { phase = .signedOut }
        case .authenticated:
            phase = .signedIn
            errorMessage = nil
        @unknown default:
            phase = .signedOut
        }
    }

    // MARK: - Email login flow

    func sendCode(to email: String) async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await privy.email.sendCode(to: trimmed)
            pendingEmail = trimmed
            phase = .awaitingCode
        } catch {
            print("[Privy] sendCode error: \(error) — \(error.localizedDescription)")
            errorMessage = "Couldn't send the code. Check the address and try again."
        }
    }

    func verifyCode(_ code: String) async {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await privy.email.loginWithCode(trimmed, sentTo: pendingEmail)
            // authStateStream flips us to .signedIn.
        } catch {
            errorMessage = "That code didn't work. Double-check it and try again."
        }
    }

    func startOver() {
        pendingEmail = ""
        errorMessage = nil
        phase = .signedOut
    }

    func signOut() async {
        if let user = privy.user {
            await user.logout()
        }
        startOver()
    }

    // MARK: - Token access

    /// Fresh bearer token for API requests. Privy refreshes as needed, so this
    /// is called per request and never cached.
    func accessToken() async throws -> String {
        guard let user = privy.user else {
            throw DecipherAPIError.unauthorized
        }
        return try await user.getAccessToken()
    }
}
