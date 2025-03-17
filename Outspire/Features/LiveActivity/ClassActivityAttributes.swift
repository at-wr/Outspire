import Foundation
import ActivityKit

struct ClassActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic content that can change during updates
        var startTime: Date
        var endTime: Date
        var currentStatus: ClassStatus
        var periodNumber: Int
        var progress: Double // Add progress for UI visualization
        var timeRemaining: TimeInterval // Add time remaining for simpler display
    }
    
    // Static content that doesn't change during the activity lifecycle
    var className: String
    var roomNumber: String
    var teacherName: String
    
    enum ClassStatus: String, Codable {
        case upcoming
        case ongoing
        case ending   // last 5 minutes
    }
}
