//
//  CurrentNextClassWidget.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import WidgetKit
import SwiftUI

struct CurrentNextClassProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CurrentNextClassWidgetEntry {
        CurrentNextClassWidgetEntry.placeholder(configuration: CurrentNextClassWidgetConfigurationIntent())
    }

    func snapshot(for configuration: CurrentNextClassWidgetConfigurationIntent, in context: Context) async -> CurrentNextClassWidgetEntry {
        // For preview, return a placeholder with sample data
        if context.isPreview {
            let calendar = Calendar.current
            let now = Date()
            let currentStartTime = calendar.date(bySettingHour: 10, minute: 45, second: 0, of: now)!
            let currentEndTime = calendar.date(bySettingHour: 11, minute: 25, second: 0, of: now)!

            let nextStartTime = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now)!
            let nextEndTime = calendar.date(bySettingHour: 13, minute: 10, second: 0, of: now)!

            let currentClass = ClassWidgetData(
                className: "Mathematics",
                teacherName: "Mr. Smith",
                roomNumber: "A101",
                periodNumber: 4,
                startTime: currentStartTime,
                endTime: currentEndTime,
                isCurrentClass: true,
                isSelfStudy: false
            )

            let nextClass = ClassWidgetData(
                className: "Science",
                teacherName: "Ms. Johnson",
                roomNumber: "B202",
                periodNumber: 5,
                startTime: nextStartTime,
                endTime: nextEndTime,
                isCurrentClass: false,
                isSelfStudy: false
            )

            return CurrentNextClassWidgetEntry(
                date: now,
                state: .hasClasses,
                currentClass: currentClass,
                nextClass: nextClass,
                configuration: configuration
            )
        }

        // Otherwise, return real data
        return await getTimelineEntry(for: configuration)
    }

    func timeline(for configuration: CurrentNextClassWidgetConfigurationIntent, in context: Context) async -> Timeline<CurrentNextClassWidgetEntry> {
        // Get the current entry
        let entry = await getTimelineEntry(for: configuration)

        // Calculate next update time based on the widget state
        let nextUpdateDate: Date

        switch entry.state {
        case .hasClasses:
            // Find the next class transition time
            let now = Date()
            var nextTransition = Date().addingTimeInterval(15 * 60) // Default: 15 minutes

            // If there's a current class, update when it ends
            if let currentClass = entry.currentClass, currentClass.endTime > now {
                nextTransition = min(nextTransition, currentClass.endTime)
            }

            // If there's a next class, update when it starts
            if let nextClass = entry.nextClass, nextClass.startTime > now {
                nextTransition = min(nextTransition, nextClass.startTime)
            }

            // Update at the next transition or at most in 15 minutes
            nextUpdateDate = nextTransition

        case .loading:
            // If loading, try again in 30 seconds
            nextUpdateDate = Date().addingTimeInterval(30)

        case .notSignedIn, .weekend, .holiday, .noClasses:
            // For static states, update less frequently
            nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        }

        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }

    // Helper method to get the current timeline entry
    private func getTimelineEntry(for configuration: CurrentNextClassWidgetConfigurationIntent) async -> CurrentNextClassWidgetEntry {
        // Check if user is signed in
        if !WidgetDataService.shared.isUserSignedIn() {
            return CurrentNextClassWidgetEntry.notSignedIn(configuration: configuration)
        }

        // Check if it's weekend
        if WidgetHelpers.isCurrentDateWeekend() {
            return CurrentNextClassWidgetEntry.weekend(configuration: configuration)
        }

        // Check if holiday mode is enabled
        if WidgetDataService.shared.isHolidayModeEnabled() {
            let endDate = WidgetDataService.shared.getHolidayEndDate()
            return CurrentNextClassWidgetEntry.holiday(endDate: endDate, configuration: configuration)
        }

        // Get current and next class
        let (currentClass, upcomingClasses) = WidgetDataService.shared.getCurrentOrNextClass()

        // If we have a current class, use it and the first upcoming class
        if let currentClass = currentClass {
            let nextClass = upcomingClasses.first

            return CurrentNextClassWidgetEntry(
                date: Date(),
                state: .hasClasses,
                currentClass: currentClass,
                nextClass: nextClass,
                configuration: configuration
            )
        }
        // If we don't have a current class but have an upcoming class, use it as the next class
        else if let nextClass = upcomingClasses.first {
            return CurrentNextClassWidgetEntry(
                date: Date(),
                state: .hasClasses,
                currentClass: nil,
                nextClass: nextClass,
                configuration: configuration
            )
        }
        // No classes
        else {
            return CurrentNextClassWidgetEntry(
                date: Date(),
                state: .noClasses,
                currentClass: nil,
                nextClass: nil,
                configuration: configuration
            )
        }
    }
}

struct CurrentNextClassWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: CurrentNextClassProvider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            accessoryInlineView(entry: entry)
                .widgetAccentable()
        case .accessoryRectangular:
            accessoryRectangularView(entry: entry)
                .widgetAccentable()
                .containerBackground(.clear, for: .widget)
        default:
            ZStack {
                // Background
                Color(UIColor.systemBackground)

                // Content based on state
                switch entry.state {
                case .notSignedIn:
                    notSignedInView
                case .loading:
                    loadingView
                case .weekend:
                    weekendView
                case .holiday(let endDate):
                    holidayView(endDate: endDate)
                case .noClasses:
                    noClassesView
                case .hasClasses:
                    currentNextClassView
                        .padding(.vertical, 4) // Adding vertical padding to create more space from edges
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }

    // MARK: - State Views

    private var notSignedInView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            Text("Not Signed In")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Sign in to Outspire to view your classes")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            // Skeleton for class name
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .cornerRadius(4)
                .padding(.horizontal, 12)

            // Skeleton for teacher name
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 15)
                .cornerRadius(4)
                .padding(.horizontal, 12)

            // Skeleton for room number
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 15)
                .cornerRadius(4)
                .padding(.horizontal, 12)
        }
    }

    private var weekendView: some View {
        VStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 28))
                .foregroundStyle(.yellow)

            Text("It's the Weekend!")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Enjoy your time off")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func holidayView(endDate: Date?) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)

            Text("Holiday Mode")
                .font(.headline)
                .multilineTextAlignment(.center)

            if let endDate = endDate {
                // Create the formatted date string outside the view hierarchy
                let formattedDate: String = {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    return formatter.string(from: endDate)
                }()

                Text("Until \(formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Enjoy your time off")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var noClassesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.green)

            Text("No Classes")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("No more classes scheduled for today")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Current Next Class View

    private var currentNextClassView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - more compact for small widget
            if widgetFamily != .systemSmall {
                Text("Classes")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                Divider()
                    .padding(.horizontal, 16)
            }

            // Content based on widget size
            if widgetFamily == .systemSmall {
                compactClassView
            } else {
                regularClassView
            }
        }
        .frame(maxHeight: .infinity)
    }

    // Compact view for small widget
    private var compactClassView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Current class section (if available)
            if let currentClass = entry.currentClass {
                compactClassItemView(
                    classData: currentClass,
                    isCurrentClass: true
                )
            } else {
                // Empty current class placeholder
                emptyCompactClassItemView(isCurrentClass: true)
            }

            // Divider between classes
            Divider()
                .padding(.horizontal, 12)

            // Next class section (if available)
            if let nextClass = entry.nextClass {
                compactClassItemView(
                    classData: nextClass,
                    isCurrentClass: false
                )
            } else {
                // Empty next class placeholder
                emptyCompactClassItemView(isCurrentClass: false)
            }

            // If no classes are available at all
            if entry.currentClass == nil && entry.nextClass == nil {
                // This is now handled by the empty placeholders above
            }
        }
        .padding(.top, 14) // Increased top padding for small widget
    }

    // Regular view for medium widget
    private var regularClassView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Current class section
            if let currentClass = entry.currentClass {
                classItemView(
                    classData: currentClass,
                    isCurrentClass: true,
                    showDetails: entry.configuration.showClassDetails
                )
            } else {
                // Empty current class placeholder
                emptyClassItemView(isCurrentClass: true)
            }

            // Divider between classes
            Divider()
                .padding(.horizontal, 14)

            // Next class section
            if let nextClass = entry.nextClass {
                classItemView(
                    classData: nextClass,
                    isCurrentClass: false,
                    showDetails: entry.configuration.showClassDetails
                )
            } else {
                // Empty next class placeholder
                emptyClassItemView(isCurrentClass: false)
            }

            // If no classes are available at all
            if entry.currentClass == nil && entry.nextClass == nil {
                // This is now handled by the empty placeholders above
            }
        }
    }

    // Empty placeholder for compact view
    private func emptyCompactClassItemView(isCurrentClass: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Status badge
            HStack {
                Text(isCurrentClass ? "Current" : "Next")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                    )
                    .foregroundStyle(.gray)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            // Empty message
            Text(isCurrentClass ? "No current class" : "No upcoming class")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
    }

    // Empty placeholder for regular view
    private func emptyClassItemView(isCurrentClass: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Status badge
            HStack {
                Text(isCurrentClass ? "Current" : "Next")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                    )
                    .foregroundStyle(.gray)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            // Empty message
            Text(isCurrentClass ? "No current class" : "No upcoming class")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
        }
    }

    // Compact no classes view
    private var noClassesCompactView: some View {
        VStack(spacing: 4) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green)

            Text("No Classes")
                .font(.callout)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // Compact class item view for small widget
    private func compactClassItemView(classData: ClassWidgetData, isCurrentClass: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) { // Reduced spacing
            // Status and period in one line
            HStack {
                Text(isCurrentClass ? "Current" : "Next")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 4) // Reduced horizontal padding
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(classColor(for: classData).opacity(0.15))
                    )
                    .foregroundStyle(classColor(for: classData))

                Spacer()

                Text("P\(classData.periodNumber)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4) // Reduced top padding

            // Class name with better truncation
            Text(classData.className)
                .font(.callout)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.9)
                .padding(.horizontal, 12)
                .padding(.bottom, 1) // Reduced bottom padding

            // Teacher and room combined in one line with better truncation
            if !classData.teacherName.isEmpty || !classData.roomNumber.isEmpty {
                Text("\(classData.teacherName)\(!classData.teacherName.isEmpty && !classData.roomNumber.isEmpty ? " • " : "")\(classData.roomNumber)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 3) // Reduced bottom padding
            }
        }
    }

    // Regular class item view for medium widget
    private func classItemView(classData: ClassWidgetData, isCurrentClass: Bool, showDetails: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) { // Reduced spacing
            // Status badge
            HStack {
                Text(isCurrentClass ? "Current" : "Next")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 5) // Reduced padding
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(classColor(for: classData).opacity(0.15))
                    )
                    .foregroundStyle(classColor(for: classData))

                Spacer()

                Text("Period \(classData.periodNumber)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 6) // Reduced top padding

            // Class name with improved truncation
            Text(classData.className)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.9)
                .padding(.horizontal, 14)
                .padding(.top, 1) // Tiny top padding

            // Details with improved spacing and truncation
            if showDetails {
                HStack(spacing: 4) { // Reduced spacing
                    // Teacher name with icon
                    if !classData.teacherName.isEmpty {
                        Label {
                            Text(classData.teacherName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        } icon: {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                                .imageScale(.small)
                        }
                        .font(.caption2)
                    }

                    // Room number with icon
                    if !classData.roomNumber.isEmpty {
                        Label {
                            Text(classData.roomNumber)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        } icon: {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.secondary)
                                .imageScale(.small)
                        }
                        .font(.caption2)
                    }

                    Spacer(minLength: 2)

                    // Time range with better truncation
                    Text(classData.timeRangeFormatted)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.bottom, 3) // Reduced bottom padding
            } else {
                Spacer()
                    .frame(height: 1) // Minimal spacer
            }
        }
    }

    // MARK: - Accessory Views

    // Accessory inline view - shows minimal info
    private func accessoryInlineView(entry: CurrentNextClassProvider.Entry) -> some View {
        if case .hasClasses = entry.state {
            if let currentClass = entry.currentClass {
                // During class, show class name and end time
                let endTimeString = formatAccessoryTime(currentClass.endTime)
                return Text("\(currentClass.className) ends \(endTimeString)")
            } else if let nextClass = entry.nextClass {
                // Before class, show next class and start time
                let startTimeString = formatAccessoryTime(nextClass.startTime)
                return Text("Next: \(nextClass.className) at \(startTimeString)")
            }
        }

        // Default state
        return Text("No classes")
    }

    // Accessory rectangular view - shows more details
    private func accessoryRectangularView(entry: CurrentNextClassProvider.Entry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if case .hasClasses = entry.state {
                if let currentClass = entry.currentClass {
                    // Current class info
                    Text("Current: \(currentClass.className)")
                        .font(.headline)
                        .lineLimit(1)

                    // Only show teacher name
                    if !currentClass.teacherName.isEmpty {
                        Text(currentClass.teacherName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else if let nextClass = entry.nextClass {
                    // Next class info
                    Text("Next: \(nextClass.className)")
                        .font(.headline)
                        .lineLimit(1)

                    // Only show teacher name
                    if !nextClass.teacherName.isEmpty {
                        Text(nextClass.teacherName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                // Default state
                Text("No classes")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Helper to format time for accessory views
    private func formatAccessoryTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Helper Methods

    private func classColor(for classData: ClassWidgetData) -> Color {
        if classData.isSelfStudy {
            return .purple
        } else {
            return WidgetHelpers.getSubjectColor(from: classData.className)
        }
    }
}

// MARK: - Widget Configuration

struct CurrentNextClassWidget: Widget {
    let kind: String = "CurrentNextClassWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CurrentNextClassWidgetConfigurationIntent.self, provider: CurrentNextClassProvider()) { entry in
            CurrentNextClassWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Current & Next Class")
        .description("View your current and next class at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

extension CurrentNextClassWidgetConfigurationIntent {
    fileprivate static var defaultConfig: CurrentNextClassWidgetConfigurationIntent {
        let intent = CurrentNextClassWidgetConfigurationIntent()
        intent.showClassDetails = true
        return intent
    }

    fileprivate static var minimalConfig: CurrentNextClassWidgetConfigurationIntent {
        let intent = CurrentNextClassWidgetConfigurationIntent()
        intent.showClassDetails = false
        return intent
    }
}

#Preview(as: .systemMedium) {
    CurrentNextClassWidget()
} timeline: {
    // Create sample data for preview
    let calendar = Calendar.current
    let now = Date()
    let currentStartTime = calendar.date(bySettingHour: 10, minute: 45, second: 0, of: now)!
    let currentEndTime = calendar.date(bySettingHour: 11, minute: 25, second: 0, of: now)!

    let nextStartTime = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now)!
    let nextEndTime = calendar.date(bySettingHour: 13, minute: 10, second: 0, of: now)!

    let currentClass = ClassWidgetData(
        className: "Mathematics",
        teacherName: "Mr. Smith",
        roomNumber: "A101",
        periodNumber: 4,
        startTime: currentStartTime,
        endTime: currentEndTime,
        isCurrentClass: true,
        isSelfStudy: false
    )

    let nextClass = ClassWidgetData(
        className: "Science",
        teacherName: "Ms. Johnson",
        roomNumber: "B202",
        periodNumber: 5,
        startTime: nextStartTime,
        endTime: nextEndTime,
        isCurrentClass: false,
        isSelfStudy: false
    )

    // Entry with both current and next class
    CurrentNextClassWidgetEntry(
        date: now,
        state: .hasClasses,
        currentClass: currentClass,
        nextClass: nextClass,
        configuration: .defaultConfig
    )

    // Entry with only current class
    CurrentNextClassWidgetEntry(
        date: now,
        state: .hasClasses,
        currentClass: currentClass,
        nextClass: nil,
        configuration: .defaultConfig
    )

    // Entry with only next class
    CurrentNextClassWidgetEntry(
        date: now,
        state: .hasClasses,
        currentClass: nil,
        nextClass: nextClass,
        configuration: .defaultConfig
    )

    // Weekend entry
    CurrentNextClassWidgetEntry(
        date: now,
        state: .weekend,
        currentClass: nil,
        nextClass: nil,
        configuration: .defaultConfig
    )
}
