import Foundation

#if !targetEnvironment(macCatalyst)
    import ActivityKit

    struct ClassActivityAttributes: ActivityAttributes {
        struct ScheduledClass: Codable, Hashable, Identifiable {
            let id: UUID
            let className: String
            let teacherName: String
            let roomNumber: String
            let periodNumber: Int
            let startTime: Date
            let endTime: Date
        }

        struct ContentState: Codable, Hashable {
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
