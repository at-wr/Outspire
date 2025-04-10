//
//  OutspireWidgetControl.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import WidgetKit
import SwiftUI

struct ClassTableProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClassTableWidgetEntry {
        ClassTableWidgetEntry.placeholder(configuration: ClassTableWidgetConfigurationIntent())
    }

    func snapshot(for configuration: ClassTableWidgetConfigurationIntent, in context: Context) async -> ClassTableWidgetEntry {
        // For preview, return a placeholder with sample data
        if context.isPreview {
            let calendar = Calendar.current
            let now = Date()

            // Create sample classes
            var sampleClasses: [ClassWidgetData] = []

            for i in 1...5 {
                let startHour = 8 + i
                let endHour = startHour + 1

                let startTime = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: now)!
                let endTime = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: now)!

                let isCurrentClass = i == 2

                sampleClasses.append(ClassWidgetData(
                    className: ["Mathematics", "English", "Science", "History", "Art"][i-1],
                    teacherName: "Teacher \(i)",
                    roomNumber: "Room \(100 + i)",
                    periodNumber: i,
                    startTime: startTime,
                    endTime: endTime,
                    isCurrentClass: isCurrentClass,
                    isSelfStudy: i == 4
                ))
            }

            return ClassTableWidgetEntry(
                date: now,
                state: .hasClasses,
                classes: sampleClasses,
                dayOfWeek: "Mon",
                configuration: configuration
            )
        }

        // Otherwise, return real data
        return await getTimelineEntry(for: configuration)
    }

    func timeline(for configuration: ClassTableWidgetConfigurationIntent, in context: Context) async -> Timeline<ClassTableWidgetEntry> {
        // Get the current entry
        let entry = await getTimelineEntry(for: configuration)

        // Calculate next update time based on the widget state
        let nextUpdateDate: Date

        switch entry.state {
        case .hasClasses:
            // Find the next class transition time
            let now = Date()
            var nextTransition = Date().addingTimeInterval(15 * 60) // Default: 15 minutes

            // Find the next class start or end time
            for classData in entry.classes {
                if classData.isCurrentClass {
                    // If this is the current class, next transition is when it ends
                    if classData.endTime > now {
                        nextTransition = min(nextTransition, classData.endTime)
                    }
                } else if classData.startTime > now {
                    // If this is an upcoming class, next transition is when it starts
                    nextTransition = min(nextTransition, classData.startTime)
                }
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
    private func getTimelineEntry(for configuration: ClassTableWidgetConfigurationIntent) async -> ClassTableWidgetEntry {
        // Check if user is signed in
        if !WidgetDataService.shared.isUserSignedIn() {
            return ClassTableWidgetEntry.notSignedIn(configuration: configuration)
        }

        // Check if it's weekend
        if WidgetHelpers.isCurrentDateWeekend() {
            return ClassTableWidgetEntry.weekend(configuration: configuration)
        }

        // Check if holiday mode is enabled
        if WidgetDataService.shared.isHolidayModeEnabled() {
            let endDate = WidgetDataService.shared.getHolidayEndDate()
            return ClassTableWidgetEntry.holiday(endDate: endDate, configuration: configuration)
        }

        // Get all classes for today
        let (dayName, allClasses) = WidgetDataService.shared.getClassesForToday()

        if !allClasses.isEmpty {
            // Filter to show the most relevant classes based on current time
            let classes = getRelevantClasses(from: allClasses)

            return ClassTableWidgetEntry(
                date: Date(),
                state: .hasClasses,
                classes: classes,
                dayOfWeek: dayName,
                configuration: configuration
            )
        } else {
            return ClassTableWidgetEntry(
                date: Date(),
                state: .noClasses,
                classes: [],
                dayOfWeek: dayName,
                configuration: configuration
            )
        }
    }

    // Helper to get the most relevant classes based on current time
    private func getRelevantClasses(from allClasses: [ClassWidgetData]) -> [ClassWidgetData] {
        let now = Date()

        // Sort classes by period number to ensure correct ordering
        let sortedClasses = allClasses.sorted(by: { $0.periodNumber < $1.periodNumber })

        // Find the current or next class
        if let currentClassIndex = sortedClasses.firstIndex(where: {
            $0.startTime <= now && $0.endTime > now
        }) {
            // We're currently in a class period, show this and subsequent classes
            return Array(sortedClasses[currentClassIndex...])
        } else if let nextClassIndex = sortedClasses.firstIndex(where: {
            $0.startTime > now
        }) {
            // No current class, but we have upcoming classes today
            return Array(sortedClasses[nextClassIndex...])
        } else {
            // No current or upcoming classes today, show all classes
            // This handles the case of looking at tomorrow's schedule
            return sortedClasses
        }
    }
}

struct OutspireWidgetControl: Widget {
    let kind: String = "OutspireWidgetControl"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ClassTableWidgetConfigurationIntent.self, provider: ClassTableProvider()) { entry in
            OutspireWidgetControlView(entry: entry)
        }
        .configurationDisplayName("Class Table Widget")
        .description("View your daily class schedule.")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct OutspireWidgetControlView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: ClassTableProvider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            accessoryRectangularView(entry: entry)
                .widgetAccentable()
                .containerBackground(.clear, for: .widget)
        default:
            ZStack {
                // Background - changed from secondarySystemBackground to systemBackground
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
                    ClassTableContentView(
                        dayOfWeek: entry.dayOfWeek,
                        configuration: entry.configuration,
                        classes: entry.classes,
                        widgetFamily: widgetFamily
                    )
                    .padding(.vertical, 4) // Adding vertical padding to create more space from edges
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }

    // MARK: - Accessory View

    @ViewBuilder
    private func accessoryRectangularView(entry: ClassTableProvider.Entry) -> some View {
        if case .hasClasses = entry.state, !entry.classes.isEmpty {
            let dayMapping = ["Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5]
            let dayIndex = dayMapping[entry.dayOfWeek] ?? 1
            let dayName = WidgetHelpers.weekdayName(for: dayIndex)
            let classCount = entry.classes.count

            VStack(alignment: .leading, spacing: 2) {
                // Day header
                Text("\(dayName)'s Classes")
                    .font(.headline)
                    .lineLimit(1)

                // First two classes
                if entry.classes.count > 0 {
                    let firstClass = entry.classes[0]
                    Text("P\(firstClass.periodNumber): \(firstClass.className)")
                        .font(.caption)
                        .lineLimit(1)
                }

                if entry.classes.count > 1 {
                    let secondClass = entry.classes[1]
                    Text("P\(secondClass.periodNumber): \(secondClass.className)")
                        .font(.caption)
                        .lineLimit(1)
                }

                // Show count of remaining classes
                if classCount > 2 {
                    Text("+ \(classCount - 2) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("No classes today")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
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
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())

            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
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

            Text("No classes scheduled for today")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Class Table Content View

struct ClassTableContentView: View {
    let dayOfWeek: String
    let configuration: ClassTableWidgetConfigurationIntent
    let classes: [ClassWidgetData]
    let widgetFamily: WidgetFamily

    // Convert dayOfWeek string to index if possible
    private var dayOfWeekIndex: Int {
        // Try to convert from string like "Mon" to index 1
        let dayMapping = ["Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5]
        return dayMapping[dayOfWeek] ?? 1 // Default to Monday if not found
    }

    // Compute how many classes to show based on widget size
    private var maxClassesToShow: Int {
        switch widgetFamily {
        case .systemLarge:
            return 8  // Reduced from 10 to avoid potential overflow
        case .systemMedium:
            return 4  // Reduced from 5 for better layout
        default:
            return 3
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with reduced padding
            headerView

            // Class list view
            classListView
        }
    }

    // Header view with day of week - more compact
    private var headerView: some View {
        HStack {
            Text(WidgetHelpers.weekdayName(for: dayOfWeekIndex))
                .font(widgetFamily == .systemLarge ? .headline : .subheadline)
                .fontWeight(.semibold)

            Spacer()

            Text("Classes")
                .font(widgetFamily == .systemLarge ? .subheadline : .caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, widgetFamily == .systemLarge ? 16 : 12)
        .padding(.top, widgetFamily == .systemLarge ? 8 : 6)
        .padding(.bottom, 3)  // Reduced padding
    }

    // Class list view - more compact VStack
    private var classListView: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, widgetFamily == .systemLarge ? 16 : 12)

            // Show classes up to the maximum allowed for this widget size
            let visibleClasses = Array(classes.prefix(maxClassesToShow))

            ForEach(Array(visibleClasses.enumerated()), id: \.element.id) { index, classData in
                VStack(spacing: 0) {
                    ClassRowView(
                        classData: classData,
                        widgetFamily: widgetFamily
                    )

                    if index < visibleClasses.count - 1 {
                        Divider()
                            .padding(.horizontal, widgetFamily == .systemLarge ? 16 : 12)
                    }
                }
            }

            // Show a "more classes" indicator if we couldn't show all classes
            if classes.count > maxClassesToShow {
                Divider()
                    .padding(.horizontal, widgetFamily == .systemLarge ? 16 : 12)

                HStack {
                    Text("+ \(classes.count - maxClassesToShow) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 3)
                }
                .padding(.horizontal, widgetFamily == .systemLarge ? 16 : 12)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Class Row View

struct ClassRowView: View {
    let classData: ClassWidgetData
    let widgetFamily: WidgetFamily

    var body: some View {
        HStack(alignment: .center, spacing: widgetFamily == .systemLarge ? 6 : 4) {
            // Period indicator - more compact
            Text("\(classData.periodNumber)")
                .font(.caption2)
                .fontWeight(.medium)
                .frame(width: widgetFamily == .systemLarge ? 18 : 16, height: widgetFamily == .systemLarge ? 18 : 16)
                .background(
                    Circle()
                        .fill(classColor(for: classData).opacity(0.15))
                )
                .foregroundStyle(classColor(for: classData))

            // Class details with optimized spacing
            VStack(alignment: .leading, spacing: 0) {
                // Class name with better truncation
                Text(classData.className)
                    .font(widgetFamily == .systemLarge ? .caption : .caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.9)

                // Only show teacher/room for large widget and optimize for space
                if widgetFamily == .systemLarge,
                   !classData.teacherName.isEmpty || !classData.roomNumber.isEmpty {
                    HStack(spacing: 2) {
                        if !classData.teacherName.isEmpty {
                            Text(classData.teacherName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .minimumScaleFactor(0.9)
                        }

                        if !classData.teacherName.isEmpty && !classData.roomNumber.isEmpty {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 1)
                        }

                        if !classData.roomNumber.isEmpty {
                            Text(classData.roomNumber)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .minimumScaleFactor(0.9)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Self-study badge - more compact
            if classData.isSelfStudy {
                Text("Self-Study")
                    .font(.caption2)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.15))
                    )
                    .foregroundStyle(.purple)
            }
        }
        .padding(.horizontal, widgetFamily == .systemLarge ? 16 : 12)
        .padding(.vertical, widgetFamily == .systemLarge ? 3 : 2) // Further reduced padding
    }

    // Helper method for class color
    private func classColor(for classData: ClassWidgetData) -> Color {
        if classData.isSelfStudy {
            return .purple
        } else {
            return WidgetHelpers.getSubjectColor(from: classData.className)
        }
    }
}

// MARK: - Preview

extension ClassTableWidgetConfigurationIntent {
    fileprivate static var defaultConfig: ClassTableWidgetConfigurationIntent {
        let intent = ClassTableWidgetConfigurationIntent()
        intent.maxClassesToShow = 3
        intent.showClassDetails = true
        return intent
    }

    fileprivate static var minimalConfig: ClassTableWidgetConfigurationIntent {
        let intent = ClassTableWidgetConfigurationIntent()
        intent.maxClassesToShow = 2
        intent.showClassDetails = false
        return intent
    }
}

#Preview(as: .systemMedium) {
    OutspireWidgetControl()
} timeline: {
    // Create sample data for preview
    let calendar = Calendar.current
    let now = Date()

    // Create sample classes
    var sampleClasses: [ClassWidgetData] = []

    for i in 1...5 {
        let startHour = 8 + i
        let endHour = startHour + 1

        let startTime = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: now)!

        let isCurrentClass = i == 2

        sampleClasses.append(ClassWidgetData(
            className: ["Mathematics", "English", "Science", "History", "Art"][i-1],
            teacherName: "Teacher \(i)",
            roomNumber: "Room \(100 + i)",
            periodNumber: i,
            startTime: startTime,
            endTime: endTime,
            isCurrentClass: isCurrentClass,
            isSelfStudy: i == 4
        ))
    }

    // Create and return the first entry
    let entry1 = ClassTableWidgetEntry(
        date: now,
        state: .hasClasses,
        classes: sampleClasses,
        dayOfWeek: "Mon",
        configuration: .defaultConfig
    )

    // Create and return the second entry
    let entry2 = ClassTableWidgetEntry(
        date: now,
        state: .weekend,
        classes: [],
        dayOfWeek: "",
        configuration: .defaultConfig
    )

    // Return entries as an array
    return [entry1, entry2]
}
