//
//  WidgetDataService.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import Foundation
import WidgetKit

private enum WidgetConfiguration {
    static let appGroupSuiteName = "group.dev.wrye.Outspire"
}

// Service for fetching data for widgets
class WidgetDataService {
    static let shared = WidgetDataService()

    private let defaults = UserDefaults(suiteName: WidgetConfiguration.appGroupSuiteName)

    private init() {}

    // Check if user is signed in
    func isUserSignedIn() -> Bool {
        // Read from shared App Group user defaults
        return defaults?.bool(forKey: "isAuthenticated") ?? false
    }

    // Check if holiday mode is enabled
    func isHolidayModeEnabled() -> Bool {
        return defaults?.bool(forKey: "isHolidayMode") ?? false
    }

    // Get holiday end date if available
    func getHolidayEndDate() -> Date? {
        let hasEndDate = defaults?.bool(forKey: "holidayHasEndDate") ?? false
        if hasEndDate {
            return defaults?.object(forKey: "holidayEndDate") as? Date
        }
        return nil
    }

    // Get current or next class period
    func getCurrentOrNextClass() -> (ClassWidgetData?, [ClassWidgetData]) {
        return getCurrentOrNextClass(at: Date())
    }

    func getCurrentOrNextClass(at date: Date) -> (ClassWidgetData?, [ClassWidgetData]) {
        // Check if we're in weekend or holiday mode
        if WidgetHelpers.isWeekend(date: date) || isHolidayModeEnabled() {
            return (nil, [])
        }

        // Get timetable data from shared UserDefaults
        guard let timetableData = defaults?.data(forKey: "widgetTimetableData"),
              let timetable = try? JSONDecoder().decode([[String]].self, from: timetableData)
        else {
            return (nil, [])
        }

        // Get current day index (0-4 for Mon-Fri)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let dayIndex = weekday == 1 || weekday == 7 ? -1 : weekday - 2

        // If it's weekend, return empty
        if dayIndex < 0 {
            return (nil, [])
        }

        // Get current or next period
        let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod(at: date)

        // If no period found, return empty
        guard let period = periodInfo.period,
              period.number < timetable.count,
              dayIndex + 1 < timetable[period.number].count
        else {
            return (nil, [])
        }

        // Get class data
        let classData = timetable[period.number][dayIndex + 1]
        let isSelfStudy = classData.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty

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
            let periods = ClassPeriodsManager.shared.classPeriods(for: date)
            for i in (period.number + 1) ..< timetable.count {
                if i < timetable.count, dayIndex + 1 < timetable[i].count,
                   let nextPeriod = periods.first(where: { $0.number == i })
                {
                    let nextClassData = timetable[i][dayIndex + 1]
                    let nextIsSelfStudy = nextClassData.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        .isEmpty

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
        let date = Date()

        // Get timetable data from shared UserDefaults
        guard let timetableData = defaults?.data(forKey: "widgetTimetableData"),
              let timetable = try? JSONDecoder().decode([[String]].self, from: timetableData)
        else {
            return ("", [])
        }

        // Get current day index (0-4 for Mon-Fri)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
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
        let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod(at: date)
        let currentPeriodNumber = periodInfo.isCurrentlyActive ? periodInfo.period?.number : nil

        // Loop through all periods
        let periods = ClassPeriodsManager.shared.classPeriods(for: date)
        for i in 1 ..< timetable.count {
            if i < timetable.count, dayIndex + 1 < timetable[i].count,
               let period = periods.first(where: { $0.number == i })
            {
                let classData = timetable[i][dayIndex + 1]
                let isSelfStudy = classData.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty

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
    static let shared = ClassPeriodsManager()

    // All periods for the day
    var classPeriods: [ClassPeriod] {
        classPeriods(for: Date())
    }

    func classPeriods(for date: Date) -> [ClassPeriod] {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)

        return [
            createPeriod(number: 1, hour: 8, minute: 15, endHour: 8, endMinute: 55, date: day),
            createPeriod(number: 2, hour: 9, minute: 5, endHour: 9, endMinute: 45, date: day),
            createPeriod(number: 3, hour: 9, minute: 55, endHour: 10, endMinute: 35, date: day),
            createPeriod(number: 4, hour: 10, minute: 45, endHour: 11, endMinute: 25, date: day),
            createPeriod(number: 5, hour: 12, minute: 30, endHour: 13, endMinute: 10, date: day),
            createPeriod(number: 6, hour: 13, minute: 20, endHour: 14, endMinute: 0, date: day),
            createPeriod(number: 7, hour: 14, minute: 10, endHour: 14, endMinute: 50, date: day),
            createPeriod(number: 8, hour: 15, minute: 0, endHour: 15, endMinute: 40, date: day),
            createPeriod(number: 9, hour: 15, minute: 50, endHour: 16, endMinute: 30, date: day)
        ]
    }

    // Find current or next period
    func getCurrentOrNextPeriod(at referenceDate: Date = Date()) -> (period: ClassPeriod?, isCurrentlyActive: Bool) {
        let periods = classPeriods(for: referenceDate)
        if let activePeriod = periods.first(where: { $0.isActive(at: referenceDate) }) {
            return (activePeriod, true)
        }
        let futurePeriods = periods.filter { $0.startTime > referenceDate }
        if let nextPeriod = futurePeriods.min(by: { $0.startTime < $1.startTime }) {
            return (nextPeriod, false)
        }
        return (nil, false)
    }

    // Helper to create a period
    private func createPeriod(
        number: Int,
        hour: Int,
        minute: Int,
        endHour: Int,
        endMinute: Int,
        date: Date
    ) -> ClassPeriod {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
        let endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date) ?? date

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

    public func isActive(at date: Date) -> Bool {
        date >= startTime && date <= endTime
    }
}
