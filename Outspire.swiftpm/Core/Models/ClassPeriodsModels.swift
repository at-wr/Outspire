import Foundation
import SwiftUI

public struct ClassPeriod: Identifiable {
    public let id = UUID()
    public let number: Int
    public let startTime: Date
    public let endTime: Date
    
    // Helper to check if current time is within this period
    public func isCurrentlyActive() -> Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
    
    // Calculate percentage of period completed (for indicator positioning)
    public func currentProgressPercentage() -> CGFloat {
        let now = Date()
        if now < startTime { return 0 }
        if now > endTime { return 1 }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsedDuration = now.timeIntervalSince(startTime)
        return CGFloat(elapsedDuration / totalDuration)
    }
    
    // Format for display
    public var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        
        let startString = formatter.string(from: startTime)
        let endString = formatter.string(from: endTime)
        
        formatter.dateFormat = "a"
        let startAmPm = formatter.string(from: startTime)
        let endAmPm = formatter.string(from: endTime)
        
        if startAmPm == endAmPm {
            return "\(startString)-\(endString) \(endAmPm)"
        } else {
            return "\(startString) \(startAmPm)-\(endString) \(endAmPm)"
        }
    }
}

public class ClassPeriodsManager {
    public static let shared = ClassPeriodsManager()
    
    // All periods for the day
    public var classPeriods: [ClassPeriod] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return [
            createPeriod(number: 1, hour: 8, minute: 15, endHour: 8, endMinute: 55, date: today),
            createPeriod(number: 2, hour: 9, minute: 5, endHour: 9, endMinute: 45, date: today),
            createPeriod(number: 3, hour: 9, minute: 55, endHour: 10, endMinute: 35, date: today),
            createPeriod(number: 4, hour: 10, minute: 45, endHour: 11, endMinute: 25, date: today),
            createPeriod(number: 5, hour: 12, minute: 30, endHour: 13, endMinute: 10, date: today),
            createPeriod(number: 6, hour: 13, minute: 20, endHour: 14, endMinute: 0, date: today),
            createPeriod(number: 7, hour: 14, minute: 10, endHour: 14, endMinute: 50, date: today),
            createPeriod(number: 8, hour: 15, minute: 0, endHour: 15, endMinute: 40, date: today),
            createPeriod(number: 9, hour: 15, minute: 50, endHour: 16, endMinute: 30, date: today)
        ]
    }
    
    // Find current or next period
    public func getCurrentOrNextPeriod() -> (period: ClassPeriod?, isCurrentlyActive: Bool) {
        let now = Date()
        
        // Check if we're currently in a period
        if let activePeriod = classPeriods.first(where: { $0.isCurrentlyActive() }) {
            return (activePeriod, true)
        }
        
        // Find next period
        let futurePeriods = classPeriods.filter { $0.startTime > now }
        if let nextPeriod = futurePeriods.min(by: { $0.startTime < $1.startTime }) {
            return (nextPeriod, false)
        }
        
        return (nil, false)
    }
    
    // Helper to create a period
    private func createPeriod(number: Int, hour: Int, minute: Int, endHour: Int, endMinute: Int, date: Date) -> ClassPeriod {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
        let endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date)!
        
        return ClassPeriod(number: number, startTime: startTime, endTime: endTime)
    }
}
