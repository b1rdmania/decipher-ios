import Foundation

/// Push-to-talk control messages sent to the remote agent over the LiveKit data
/// channel as JSON text with reliable delivery. The agent expects exactly these
/// shapes (see CLAUDE.md).
enum PTTMessage {
    case micReady(trackSid: String)
    case pttPress
    case pttRelease

    func encoded() -> Data {
        let object: [String: Any]
        switch self {
        case .micReady(let trackSid):
            object = ["type": "mic_ready", "hasMicPublication": true, "trackSid": trackSid]
        case .pttPress:
            object = ["type": "ptt_press", "hasMicPublication": true]
        case .pttRelease:
            object = ["type": "ptt_release"]
        }
        return (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
    }
}
