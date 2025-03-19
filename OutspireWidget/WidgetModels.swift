//
//  WidgetModels.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import Foundation
import SwiftUI
import WidgetKit

// Enum to represent the widget state
enum WidgetState {
    case notSignedIn
    case loading
    case weekend
    case holiday(endDate: Date?)
    case noClasses
    case hasClasses
}

// Model for class data in widgets
struct ClassWidgetData: Identifiable {
    let id = UUID() // Add id for Identifiable conformance
    let className: String
    let teacherName: String
    let roomNumber: String
    let periodNumber: Int
    let startTime: Date
    let endTime: Date
    let isCurrentClass: Bool
    let isSelfStudy: Bool
    
    // Target date for countdown - this will be used with Text's dynamic date capabilities
    var targetDate: Date {
        return isCurrentClass ? endTime : startTime
    }
    
    // Computed properties
    var timeRemaining: TimeInterval {
        // Always calculate based on current time to ensure up-to-date values
        if isCurrentClass {
            return max(0, endTime.timeIntervalSince(Date()))
        } else {
            return max(0, startTime.timeIntervalSince(Date()))
        }
    }
    
    var formattedTimeRemaining: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        if let formatted = formatter.string(from: timeRemaining) {
            // If it has hours, keep the full format
            if formatted.contains(":") && formatted.split(separator: ":").count == 3 {
                return formatted
            }
            // Otherwise just show minutes:seconds
            let components = formatted.split(separator: ":")
            if components.count == 2 {
                return "\(components[0]):\(components[1])"
            }
            return "00:\(formatted.padding(toLength: 2, withPad: "0", startingAt: 0))"
        }
        return "00:00"
    }
    
    // Add a date range for timer-based progress
    var progressRange: ClosedRange<Date> {
        startTime...endTime
    }
    
    var timeRangeFormatted: String {
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
    
    var statusText: String {
        if isCurrentClass {
            return "Current Class"
        } else {
            return "Upcoming Class"
        }
    }
    
    var progress: Double {
        if isCurrentClass {
            let totalDuration = endTime.timeIntervalSince(startTime)
            let elapsed = totalDuration - timeRemaining
            return max(0, min(1, elapsed / totalDuration))
        }
        return 0
    }
    
    // Helper to parse class data from string format
    static func fromClassData(classData: String, period: ClassPeriod, isCurrentClass: Bool) -> ClassWidgetData {
        let components = classData.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
        
        let isSelfStudy = classData.contains("Self-Study") || components.count <= 1
        
        return ClassWidgetData(
            className: components.count > 1 ? components[1] : (isSelfStudy ? "Self-Study" : "Class"),
            teacherName: components.count > 0 ? components[0] : "",
            roomNumber: components.count > 2 ? components[2] : "",
            periodNumber: period.number,
            startTime: period.startTime,
            endTime: period.endTime,
            isCurrentClass: isCurrentClass,
            isSelfStudy: isSelfStudy
        )
    }
}

// Model for widget entry
struct WidgetEntry: TimelineEntry {
    let date: Date
    let state: WidgetState
    let classData: ClassWidgetData?
    let upcomingClasses: [ClassWidgetData]
    let configuration: ClassWidgetConfigurationIntent
    
    // Computed property to get up-to-date class data
    var currentClassData: ClassWidgetData? {
        guard let classData = classData else { return nil }
        
        // If the class has ended or started since this entry was created,
        // we should update the isCurrentClass flag
        let now = Date()
        let isCurrentNow = now >= classData.startTime && now < classData.endTime
        
        // If the current status matches what we have, return the original
        if isCurrentNow == classData.isCurrentClass {
            return classData
        }
        
        // Otherwise create a new instance with updated status
        return ClassWidgetData(
            className: classData.className,
            teacherName: classData.teacherName,
            roomNumber: classData.roomNumber,
            periodNumber: classData.periodNumber,
            startTime: classData.startTime,
            endTime: classData.endTime,
            isCurrentClass: isCurrentNow,
            isSelfStudy: classData.isSelfStudy
        )
    }
    
    // Default initializer for placeholder and error states
    static func placeholder(configuration: ClassWidgetConfigurationIntent) -> WidgetEntry {
        return WidgetEntry(
            date: Date(),
            state: .loading,
            classData: nil,
            upcomingClasses: [],
            configuration: configuration
        )
    }
    
    static func notSignedIn(configuration: ClassWidgetConfigurationIntent) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            state: .notSignedIn,
            classData: nil,
            upcomingClasses: [],
            configuration: configuration
        )
    }
    
    static func weekend(configuration: ClassWidgetConfigurationIntent) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            state: .weekend,
            classData: nil,
            upcomingClasses: [],
            configuration: configuration
        )
    }
    
    static func holiday(endDate: Date?, configuration: ClassWidgetConfigurationIntent) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            state: .holiday(endDate: endDate),
            classData: nil,
            upcomingClasses: [],
            configuration: configuration
        )
    }
}

// Model for class table widget entry
struct ClassTableWidgetEntry: TimelineEntry {
    let date: Date
    let state: WidgetState
    let classes: [ClassWidgetData]
    let dayOfWeek: String
    let configuration: ClassTableWidgetConfigurationIntent
    
    // Default initializer for placeholder and error states
    static func placeholder(configuration: ClassTableWidgetConfigurationIntent) -> ClassTableWidgetEntry {
        return ClassTableWidgetEntry(
            date: Date(),
            state: .loading,
            classes: [],
            dayOfWeek: "Mon",
            configuration: configuration
        )
    }
    
    // Helper for not signed in state
    static func notSignedIn(configuration: ClassTableWidgetConfigurationIntent) -> ClassTableWidgetEntry {
        return ClassTableWidgetEntry(
            date: Date(),
            state: .notSignedIn,
            classes: [],
            dayOfWeek: "",
            configuration: configuration
        )
    }
    
    // Helper for weekend state
    static func weekend(configuration: ClassTableWidgetConfigurationIntent) -> ClassTableWidgetEntry {
        return ClassTableWidgetEntry(
            date: Date(),
            state: .weekend,
            classes: [],
            dayOfWeek: "",
            configuration: configuration
        )
    }
    
    // Helper for holiday state
    static func holiday(endDate: Date?, configuration: ClassTableWidgetConfigurationIntent) -> ClassTableWidgetEntry {
        return ClassTableWidgetEntry(
            date: Date(),
            state: .holiday(endDate: endDate),
            classes: [],
            dayOfWeek: "",
            configuration: configuration
        )
    }
}

// Model for current and next class widget entry
struct CurrentNextClassWidgetEntry: TimelineEntry {
    let date: Date
    let state: WidgetState
    let currentClass: ClassWidgetData?
    let nextClass: ClassWidgetData?
    let configuration: CurrentNextClassWidgetConfigurationIntent
    
    // Default initializer for placeholder and error states
    static func placeholder(configuration: CurrentNextClassWidgetConfigurationIntent) -> CurrentNextClassWidgetEntry {
        return CurrentNextClassWidgetEntry(
            date: Date(),
            state: .loading,
            currentClass: nil,
            nextClass: nil,
            configuration: configuration
        )
    }
    
    // Helper for not signed in state
    static func notSignedIn(configuration: CurrentNextClassWidgetConfigurationIntent) -> CurrentNextClassWidgetEntry {
        return CurrentNextClassWidgetEntry(
            date: Date(),
            state: .notSignedIn,
            currentClass: nil,
            nextClass: nil,
            configuration: configuration
        )
    }
    
    // Helper for weekend state
    static func weekend(configuration: CurrentNextClassWidgetConfigurationIntent) -> CurrentNextClassWidgetEntry {
        return CurrentNextClassWidgetEntry(
            date: Date(),
            state: .weekend,
            currentClass: nil,
            nextClass: nil,
            configuration: configuration
        )
    }
    
    // Helper for holiday state
    static func holiday(endDate: Date?, configuration: CurrentNextClassWidgetConfigurationIntent) -> CurrentNextClassWidgetEntry {
        return CurrentNextClassWidgetEntry(
            date: Date(),
            state: .holiday(endDate: endDate),
            currentClass: nil,
            nextClass: nil,
            configuration: configuration
        )
    }
}

// Helper functions for widgets
struct WidgetHelpers {
    static func weekdayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        guard index >= 1 && index <= 5 else { return "" }
        return days[index - 1]
    }
    
    static func isCurrentDateWeekend() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7
    }
    
    static func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    static func getSubjectColor(from subject: String) -> Color {
        let colors: [Color: [String]] = [
            .blue.opacity(0.8): ["Math", "Mathematics", "Maths"],
            .green.opacity(0.8): ["English", "Language", "Literature", "General Paper", "ESL"],
            .orange.opacity(0.8): ["Physics", "Science"],
            .purple.opacity(0.8): ["Chemistry", "Chem"],
            .teal.opacity(0.8): ["Biology", "Bio"],
            .mint.opacity(0.8): ["Further Math", "Maths Further"],
            .yellow.opacity(0.8): ["体育", "PE", "Sports", "P.E"],
            .brown.opacity(0.8): ["Economics", "Econ"],
            .cyan.opacity(0.8): ["Arts", "Art", "TOK"],
            .indigo.opacity(0.8): ["Chinese", "Mandarin", "语文"],
            .gray.opacity(0.8): ["History", "历史", "Geography", "Geo", "政治"]
        ]
        
        let subjectLower = subject.lowercased()
        
        // First, try to match the exact or longer phrases to avoid "Math" matching before "Maths Further"
        // Sort keywords by length (longest first) to prioritize more specific matches
        let allKeywords = colors.flatMap { color, keywords in
            keywords.map { (color, $0) }
        }.sorted { $0.1.count > $1.1.count }
        
        for (color, keyword) in allKeywords {
            if subjectLower.contains(keyword.lowercased()) {
                return color
            }
        }
        
        // Default color based on subject hash for consistency
        let hash = abs(subject.hashValue)
        let hue = Double(hash % 12) / 12.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }
}

// MARK: - Timeline Provider Helper

extension Provider {
    func getTimelineEntry(for configuration: ClassWidgetConfigurationIntent) async -> WidgetEntry {
        // Check if user is signed in
        if !WidgetDataService.shared.isUserSignedIn() {
            return WidgetEntry.notSignedIn(configuration: configuration)
        }
        
        // Check if it's weekend
        if WidgetHelpers.isCurrentDateWeekend() {
            return WidgetEntry.weekend(configuration: configuration)
        }
        
        // Check if holiday mode is enabled
        if WidgetDataService.shared.isHolidayModeEnabled() {
            let endDate = WidgetDataService.shared.getHolidayEndDate()
            return WidgetEntry.holiday(endDate: endDate, configuration: configuration)
        }
        
        // Get current or next class
        let (currentClass, upcomingClasses) = WidgetDataService.shared.getCurrentOrNextClass()
        
        if let currentClass = currentClass {
            return WidgetEntry(
                date: Date(),
                state: .hasClasses,
                classData: currentClass,
                upcomingClasses: upcomingClasses,
                configuration: configuration
            )
        } else {
            return WidgetEntry(
                date: Date(),
                state: .noClasses,
                classData: nil,
                upcomingClasses: [],
                configuration: configuration
            )
        }
    }
    
    func timeline(for configuration: ClassWidgetConfigurationIntent, in context: Context) async -> Timeline<WidgetEntry> {
        // Get the current entry
        let entry = await getTimelineEntry(for: configuration)
        
        // Calculate next update time based on the widget state
        var nextUpdateDate: Date = Date().addingTimeInterval(15 * 60) // Default: 15 minutes
        
        switch entry.state {
        case .hasClasses:
            if let classData = entry.classData {
                let now = Date()
                
                // For countdown, we'll rely on Text's dynamic date capabilities
                // but still need to update at class transitions
                if classData.isCurrentClass {
                    // If current class, update when it ends
                    nextUpdateDate = classData.endTime
                    
                    // If class ends soon (within 5 minutes), update more frequently
                    let timeToEnd = classData.endTime.timeIntervalSince(now)
                    if timeToEnd <= 300 && timeToEnd > 60 {
                        // Update every minute for the last 5 minutes
                        nextUpdateDate = now.addingTimeInterval(60)
                    } else if timeToEnd <= 60 && timeToEnd > 0 {
                        // Update every 10 seconds for the last minute
                        nextUpdateDate = now.addingTimeInterval(10)
                    } else if timeToEnd <= 0 {
                        // Class just ended, update immediately to show next class
                        return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(1)))
                    }
                } else {
                    // If upcoming class, update when it starts
                    nextUpdateDate = classData.startTime
                    
                    // If class starts soon (within 5 minutes), update more frequently
                    let timeToStart = classData.startTime.timeIntervalSince(now)
                    if timeToStart <= 300 && timeToStart > 60 {
                        // Update every minute for the last 5 minutes
                        nextUpdateDate = now.addingTimeInterval(60)
                    } else if timeToStart <= 60 && timeToStart > 0 {
                        // Update every 10 seconds for the last minute
                        nextUpdateDate = now.addingTimeInterval(10)
                    } else if timeToStart <= 0 {
                        // Class just started, update immediately to show as current
                        return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(1)))
                    }
                }
            }
            
        case .loading:
            // If loading, try again in 30 seconds
            nextUpdateDate = Date().addingTimeInterval(30)
            
        case .notSignedIn, .weekend, .holiday, .noClasses:
            // For static states, update less frequently
            nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        }
        
        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }
}