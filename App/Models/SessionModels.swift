import Foundation

/// Conversation scenarios offered by the backend. Slugs match the web app and
/// must not be changed (see CLAUDE.md).
enum ScenarioType: String, CaseIterable, Identifiable {
    case struggleBus = "struggle_bus"
    case orderingCoffee = "ordering_coffee"
    case meetingSomeone = "meeting_someone"
    case shopping = "shopping"
    case askingDirections = "asking_directions"
    case restaurant = "restaurant"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .struggleBus: return "Struggle Bus"
        case .orderingCoffee: return "Ordering Coffee"
        case .meetingSomeone: return "Meeting Someone"
        case .shopping: return "Shopping"
        case .askingDirections: return "Asking Directions"
        case .restaurant: return "Restaurant"
        }
    }

    var symbol: String {
        switch self {
        case .struggleBus: return "bus.fill"
        case .orderingCoffee: return "cup.and.saucer.fill"
        case .meetingSomeone: return "person.2.fill"
        case .shopping: return "bag.fill"
        case .askingDirections: return "map.fill"
        case .restaurant: return "fork.knife"
        }
    }
}

// MARK: - /api/speak/session/start response

struct SessionStart: Decodable {
    let ok: Bool
    let session: Session
    let livekit: LiveKitConnection

    struct Session: Decodable {
        let id: String
    }

    struct LiveKitConnection: Decodable {
        let url: String
        let token: String
        let roomName: String
    }
}
