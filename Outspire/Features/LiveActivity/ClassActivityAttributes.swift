import Foundation

#if !targetEnvironment(macCatalyst)
import ActivityKit

struct ClassActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var endTime: Date
        var currentStatus: ClassStatus
        var periodNumber: Int
        var progress: Double
        var timeRemaining: TimeInterval
    }

    var className: String
    var roomNumber: String
    var teacherName: String

    enum ClassStatus: String, Codable {
        case upcoming
        case ongoing
        case ending
    }
}
#endif
