import Foundation

/// App-wide configuration constants.
///
/// The Privy app/client IDs identify this app to Privy's auth service. Replace
/// the placeholders with the real values from the Privy dashboard for the
/// Decipher project before shipping — login will fail until they are set.
enum AppConfig {
    static let privyAppID = "REPLACE_WITH_PRIVY_APP_ID"
    static let privyClientID = "REPLACE_WITH_PRIVY_CLIENT_ID"

    /// True once real Privy credentials have been filled in.
    static var isPrivyConfigured: Bool {
        !privyAppID.hasPrefix("REPLACE_") && !privyClientID.hasPrefix("REPLACE_")
    }
}
