import Foundation

/// Thin client for the Decipher production API. No backend logic lives here —
/// every call attaches a fresh Privy bearer token supplied by `tokenProvider`.
///
/// See CLAUDE.md for the verified endpoint contract.
actor DecipherAPI {
    static let baseURL = URL(string: "https://decipher-two.vercel.app")!

    /// Returns a fresh Privy access token. Privy handles refresh internally.
    private let tokenProvider: () async throws -> String

    init(tokenProvider: @escaping () async throws -> String) {
        self.tokenProvider = tokenProvider
    }

    // MARK: - Endpoints

    /// POST /api/speak/session/start
    func startSession(scenario: ScenarioType, mode: String = "guided") async throws -> SessionStart {
        try await post(
            "/api/speak/session/start",
            body: ["scenarioType": scenario.rawValue, "mode": mode]
        )
    }

    /// POST /api/speak/session/end
    func endSession(sessionId: String, durationSec: Int) async throws {
        let _: EmptyResponse = try await post(
            "/api/speak/session/end",
            body: ["sessionId": sessionId, "durationSec": durationSec]
        )
    }

    // MARK: - Transport

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: Self.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = try await tokenProvider()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DecipherAPIError.transport
        }

        switch http.statusCode {
        case 200..<300:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw DecipherAPIError.unauthorized
        case 403:
            throw DecipherAPIError.blocked
        case 429:
            throw DecipherAPIError.budgetExceeded
        default:
            throw DecipherAPIError.server(status: http.statusCode)
        }
    }
}

/// Human-readable API failure states. Raw errors are never surfaced to the UI.
enum DecipherAPIError: LocalizedError {
    case transport
    case unauthorized
    case blocked
    case budgetExceeded
    case server(status: Int)

    var errorDescription: String? {
        switch self {
        case .transport:
            return "Couldn't reach Decipher. Check your connection and try again."
        case .unauthorized:
            return "Your session expired. Please sign in again."
        case .blocked:
            return "This account is blocked. Contact support if you think this is a mistake."
        case .budgetExceeded:
            return "You've reached this month's usage limit. Try again next month."
        case .server(let status):
            return "Something went wrong (\(status)). Please try again."
        }
    }
}

private struct EmptyResponse: Decodable {}
