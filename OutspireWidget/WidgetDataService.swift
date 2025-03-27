//
//  WidgetDataService.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import Foundation
import WidgetKit

// Service for fetching data for widgets
class WidgetDataService {
    static let shared = WidgetDataService()

    private init() {}

    // Check if user is signed in
    func isUserSignedIn() -> Bool {
        // Read from UserDefaults or keychain
        return UserDefaults(suiteName: "group.dev.wrye.Outspire")?.bool(forKey: "isAuthenticated") ?? false
    }

    // Check if holiday mode is enabled
    func isHolidayModeEnabled() -> Bool {
        return UserDefaults(suiteName: "group.dev.wrye.Outspire")?.bool(forKey: "isHolidayMode") ?? false
    }

    // Get holiday end date if available
    func getHolidayEndDate() -> Date? {
        let hasEndDate = UserDefaults(suiteName: "group.dev.wrye.Outspire")?.bool(forKey: "holidayHasEndDate") ?? false
        if hasEndDate {
            return UserDefaults(suiteName: "group.dev.wrye.Outspire")?.object(forKey: "holidayEndDate") as? Date
        }
        return nil
    }

    // Get current or next class period
    func getCurrentOrNextClass() -> (ClassWidgetData?, [ClassWidgetData]) {
        // Check if we're in weekend or holiday mode
        if WidgetHelpers.isCurrentDateWeekend() || isHolidayModeEnabled() {
            return (nil, [])
        }

        // Get timetable data from shared UserDefaults
        guard let timetableData = UserDefaults(suiteName: "group.dev.wrye.Outspire")?.data(forKey: "widgetTimetableData"),
              let timetable = try? JSONDecoder().decode([[String]].self, from: timetableData) else {
            return (nil, [])
        }

        // Get current day index (0-4 for Mon-Fri)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let dayIndex = weekday == 1 || weekday == 7 ? -1 : weekday - 2

        // If it's weekend, return empty
        if dayIndex < 0 {
            return (nil, [])
        }

        // Get current or next period
        let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod()

        // If no period found, return empty
        guard let period = periodInfo.period,
              period.number < timetable.count,
              dayIndex + 1 < timetable[period.number].count else {
            return (nil, [])
        }

        // Get class data
        let classData = timetable[period.number][dayIndex + 1]
        let isSelfStudy = classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // Create class widget data
        let currentClass = ClassWidgetData.fromClassData(
            classData: isSelfStudy ? "You\nSelf-Study" : classData,
            period: period,
            isCurrentClass: periodInfo.isCurrentlyActive
        )

        // Get upcoming classes
        var upcomingClasses: [ClassWidgetData] = []

        // If current class is active, find next classes
        if periodInfo.isCurrentlyActive {
            // Find periods after current period
            for i in (period.number + 1)..<timetable.count {
                if i < timetable.count && dayIndex + 1 < timetable[i].count,
                   let nextPeriod = ClassPeriodsManager.shared.classPeriods.first(where: { $0.number == i }) {
                    let nextClassData = timetable[i][dayIndex + 1]
                    let nextIsSelfStudy = nextClassData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                    upcomingClasses.append(ClassWidgetData.fromClassData(
                        classData: nextIsSelfStudy ? "You\nSelf-Study" : nextClassData,
                        period: nextPeriod,
                        isCurrentClass: false
                    ))

                    // Limit to 3 upcoming classes
                    if upcomingClasses.count >= 3 {
                        break
                    }
                }
            }
        }

        return (currentClass, upcomingClasses)
    }

    // Get all classes for today
    func getClassesForToday() -> (String, [ClassWidgetData]) {
        // Check if we're in weekend or holiday mode
        if WidgetHelpers.isCurrentDateWeekend() || isHolidayModeEnabled() {
            return ("", [])
        }

        // Get timetable data from shared UserDefaults
        guard let timetableData = UserDefaults(suiteName: "group.dev.wrye.Outspire")?.data(forKey: "widgetTimetableData"),
              let timetable = try? JSONDecoder().decode([[String]].self, from: timetableData) else {
            return ("", [])
        }

        // Get current day index (0-4 for Mon-Fri)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let dayIndex = weekday == 1 || weekday == 7 ? -1 : weekday - 2

        // If it's weekend, return empty
        if dayIndex < 0 {
            return ("", [])
        }

        // Get day name
        let dayName = WidgetHelpers.weekdayName(for: dayIndex + 1)

        // Get all classes for today
        var classes: [ClassWidgetData] = []

        // Find current period to mark it as active
        let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod()
        let currentPeriodNumber = periodInfo.isCurrentlyActive ? periodInfo.period?.number : nil

        // Loop through all periods
        for i in 1..<timetable.count {
            if i < timetable.count && dayIndex + 1 < timetable[i].count,
               let period = ClassPeriodsManager.shared.classPeriods.first(where: { $0.number == i }) {
                let classData = timetable[i][dayIndex + 1]
                let isSelfStudy = classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                classes.append(ClassWidgetData.fromClassData(
                    classData: isSelfStudy ? "You\nSelf-Study" : classData,
                    period: period,
                    isCurrentClass: i == currentPeriodNumber
                ))
            }
        }

        return (dayName, classes)
    }
}

// Extension of ClassPeriodsManager for widget use
class ClassPeriodsManager {
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
        if let activePeriod = classPeriods.first(where: { $0.isCurrentlyActive() }) {
            return (activePeriod, true)
        }
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

// Simple ClassPeriod struct for widget use
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
}
