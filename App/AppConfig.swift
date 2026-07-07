import Foundation

/// App-wide configuration constants.
///
/// The Privy app/client IDs identify this app to Privy's auth service. These
/// are public identifiers (shipped in the binary), not secrets — the same Privy
/// app as the web client, plus the registered iOS mobile client.
enum AppConfig {
    static let privyAppID = "cmnxhpxgr00e90cl1rvabmnna"
    static let privyClientID = "client-WY6XqEfhAUrwHGmSdyYuDA2XccqnraVKxh5Dx2pr5GcXz"

    /// True once real Privy credentials have been filled in.
    static var isPrivyConfigured: Bool {
        !privyAppID.hasPrefix("REPLACE_") && !privyClientID.hasPrefix("REPLACE_")
    }
}
