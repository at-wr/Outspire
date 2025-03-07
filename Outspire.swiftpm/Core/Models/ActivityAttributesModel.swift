import ActivityKit
import Foundation
import SwiftUI

public struct ClassActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isCurrentClass: Bool
        public var periodNumber: Int
        public var subject: String
        public var teacher: String
        public var room: String
        public var endTime: Date
        public var startTime: Date
        
        public init(
            isCurrentClass: Bool,
            periodNumber: Int,
            subject: String,
            teacher: String,
            room: String,
            endTime: Date,
            startTime: Date
        ) {
            self.isCurrentClass = isCurrentClass
            self.periodNumber = periodNumber
            self.subject = subject
            self.teacher = teacher
            self.room = room
            self.endTime = endTime
            self.startTime = startTime
        }
    }
    
    public var classDay: String
    
    public init(classDay: String) {
        self.classDay = classDay
    }
}