import Foundation

/// Enum defining the different view types in the app for navigation
enum ViewType: String, CaseIterable, Codable {
    case today
    case classtable
    case score
    case clubInfo
    case clubActivities
    case schoolArrangements
    case lunchMenu
    case map
    case notSignedIn
    case weekend
    case holiday

    var displayName: String {
        switch self {
        case .today: return "Today View"
        case .classtable: return "Class Table"
        case .score: return "Academic Grades"
        case .clubInfo: return "Club Information"
        case .clubActivities: return "Club Activities"
        case .schoolArrangements: return "School Arrangements"
        case .lunchMenu: return "Lunch Menu"
        case .map: return "Campus Map"
        case .notSignedIn: return "Not Signed In"
        case .weekend: return "Weekend"
        case .holiday: return "Holiday Mode"
        }
    }

    // Helper to create a ViewType from navigation link
    static func fromLink(_ link: String) -> ViewType? {
        switch link {
        case "today": return .today
        case "classtable": return .classtable
        case "score": return .score
        case "club-info": return .clubInfo
        case "club-activity": return .clubActivities
        case "school-arrangement": return .schoolArrangements
        case "lunch-menu": return .lunchMenu
        case "map": return .map
        default: return nil
        }
    }
}

// Add an initializer to create from navigation link
extension ViewType {
    init?(fromLink link: String) {
        switch link {
        case "today": self = .today
        case "classtable": self = .classtable
        case "score": self = .score
        case "club-info": self = .clubInfo
        case "club-activity": self = .clubActivities
        case "school-arrangement": self = .schoolArrangements
        case "lunch-menu": self = .lunchMenu
        case "map": self = .map
        default: return nil
        }
    }
}
