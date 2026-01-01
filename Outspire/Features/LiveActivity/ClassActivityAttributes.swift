import Foundation

#if !targetEnvironment(macCatalyst)
import ActivityKit

struct ClassActivityAttributes: ActivityAttributes {
    public struct ScheduledClass: Codable, Hashable, Identifiable {
        public let id: UUID
        public let className: String
        public let teacherName: String
        public let roomNumber: String
        public let periodNumber: Int
        public let startTime: Date
        public let endTime: Date
    }

    public struct ContentState: Codable, Hashable {
        var schedule: [ScheduledClass]
        var generatedAt: Date
        var finalEndDate: Date
    }

    var className: String
    var roomNumber: String
    var teacherName: String

    enum ClassStatus: String, Codable {
        case upcoming
        case ongoing
        case ending
        case completed
    }
}
#endif
