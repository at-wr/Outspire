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
    
    // Get available periods for a specific day
    public func getPeriodsForDay(date: Date) -> [ClassPeriod] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let maxPeriods = getMaxPeriodsByWeekday(weekday)
        
        return classPeriods.filter { $0.number <= maxPeriods }
    }
    
    // Get maximum number of periods based on weekday
    public func getMaxPeriodsByWeekday(_ weekday: Int) -> Int {
        // Friday is weekday 6, return 8 periods
        // For all other weekdays (Mon-Thu), return 9 periods
        return weekday == 6 ? 8 : 9
    }
    
    // Get maximum number of periods for today or a specified day
    public func getMaxPeriodsForDay(date: Date? = nil) -> Int {
        let calendar = Calendar.current
        let targetDate = date ?? Date()
        let weekday = calendar.component(.weekday, from: targetDate)
        return getMaxPeriodsByWeekday(weekday)
    }
    
    // Check if a period is a self-study period
    public func isSelfStudyPeriod(periodNumber: Int, weekday: Int, timetable: [[String]], dayIndex: Int) -> Bool {
        let maxPeriods = getMaxPeriodsByWeekday(weekday)
        
        // Check if this period is within the valid range for the day
        guard periodNumber <= maxPeriods else { return false }
        
        // Check if this period has empty data (self-study)
        guard periodNumber < timetable.count && 
                dayIndex + 1 < timetable[periodNumber].count else { return false }
        
        return timetable[periodNumber][dayIndex + 1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Find current or next period
    public func getCurrentOrNextPeriod(useEffectiveDate: Bool = false, effectiveDate: Date? = nil) -> (period: ClassPeriod?, isCurrentlyActive: Bool) {
        let currentDate = Date()
        let effectiveTime: Date
        
        if useEffectiveDate && effectiveDate != nil {
            // Use current time but on the effective date
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: currentDate)
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: effectiveDate!)
            
            var combined = DateComponents()
            combined.year = dateComponents.year
            combined.month = dateComponents.month
            combined.day = dateComponents.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute
            combined.second = timeComponents.second
            
            if let date = calendar.date(from: combined) {
                effectiveTime = date
            } else {
                effectiveTime = currentDate
            }
        } else {
            effectiveTime = currentDate
        }
        
        // Find current period
        for period in self.classPeriods {
            if effectiveTime >= period.startTime && effectiveTime <= period.endTime {
                return (period: period, isCurrentlyActive: true)
            }
        }
        
        // Find next period
        for period in self.classPeriods {
            if effectiveTime < period.startTime {
                return (period: period, isCurrentlyActive: false)
            }
        }
        
        // No current or next period found, return first period of the day
        return (period: self.classPeriods.first, isCurrentlyActive: false)
    }
    
    // Helper to create a period
    private func createPeriod(number: Int, hour: Int, minute: Int, endHour: Int, endMinute: Int, date: Date) -> ClassPeriod {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
        let endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date)!
        
        return ClassPeriod(number: number, startTime: startTime, endTime: endTime)
    }
}
