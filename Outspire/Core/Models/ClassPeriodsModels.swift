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
    public func getCurrentOrNextPeriod(useEffectiveDate: Bool = false, effectiveDate: Date? = nil) -> (period: ClassPeriod?, isCurrentlyActive: Bool) {
        if useEffectiveDate, let effectiveDate = effectiveDate {
            // Logic for finding period with effective date
            let calendar = Calendar.current
            let effectiveTime = calendar.dateComponents([.hour, .minute, .second], from: Date())
            let effectiveDay = calendar.dateComponents([.year, .month, .day], from: effectiveDate)

            var effectiveNowComponents = DateComponents()
            effectiveNowComponents.year = effectiveDay.year
            effectiveNowComponents.month = effectiveDay.month
            effectiveNowComponents.day = effectiveDay.day
            effectiveNowComponents.hour = effectiveTime.hour
            effectiveNowComponents.minute = effectiveTime.minute
            effectiveNowComponents.second = effectiveTime.second

            guard let effectiveNow = calendar.date(from: effectiveNowComponents) else {
                return (nil, false)
            }

            // Find active period
            for period in classPeriods {
                let adjustedStartTime = createAdjustedTime(from: period.startTime, onDate: effectiveDate)
                let adjustedEndTime = createAdjustedTime(from: period.endTime, onDate: effectiveDate)

                if effectiveNow >= adjustedStartTime && effectiveNow <= adjustedEndTime {
                    return (period, true)
                }
            }

            // Find next period
            let futurePeriods = classPeriods.filter {
                createAdjustedTime(from: $0.startTime, onDate: effectiveDate) > effectiveNow
            }
            if let nextPeriod = futurePeriods.min(by: {
                createAdjustedTime(from: $0.startTime, onDate: effectiveDate) <
                    createAdjustedTime(from: $1.startTime, onDate: effectiveDate)
            }) {
                return (nextPeriod, false)
            }

            return (nil, false)
        } else {
            // Regular logic
            let now = Date()
            if let activePeriod = classPeriods.first(where: { $0.isCurrentlyActive() }) {
                return (activePeriod, true)
            }
            let futurePeriods = classPeriods.filter { $0.startTime > now }
            if let nextPeriod = futurePeriods.min(by: { $0.startTime < $1.startTime }) {
                return (nextPeriod, false)
            }
            return (nil, false)
        }
    }

    // Add method to get max periods by weekday
    public func getMaxPeriodsByWeekday(_ weekday: Int) -> Int {
        // Default max periods per day (weekday is 1-7, where 1 is Sunday)
        switch weekday {
        case 2: return 9  // Monday
        case 3: return 9  // Tuesday
        case 4: return 9  // Wednesday
        case 5: return 9  // Thursday
        case 6: return 9  // Friday
        default: return 0 // Weekend
        }
    }

    // Helper method to create a time on a specific date
    private func createAdjustedTime(from time: Date, onDate date: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second

        return calendar.date(from: dateComponents) ?? date
    }

    // Helper to create a period
    private func createPeriod(number: Int, hour: Int, minute: Int, endHour: Int, endMinute: Int, date: Date) -> ClassPeriod {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
        let endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date)!

        return ClassPeriod(number: number, startTime: startTime, endTime: endTime)
    }
}
