//
//  MainWidget.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry.placeholder(configuration: ClassWidgetConfigurationIntent())
    }

    func snapshot(for configuration: ClassWidgetConfigurationIntent, in context: Context) async -> WidgetEntry {
        // For preview, return a placeholder with sample data
        if context.isPreview {
            let calendar = Calendar.current
            let now = Date()
            guard let startTime = calendar.date(bySettingHour: 10, minute: 45, second: 0, of: now),
                  let endTime = calendar.date(bySettingHour: 11, minute: 25, second: 0, of: now)
            else {
                return WidgetEntry.placeholder(configuration: configuration)
            }

            let sampleClass = ClassWidgetData(
                className: "Mathematics",
                teacherName: "Mr. Smith",
                roomNumber: "A101",
                periodNumber: 4,
                startTime: startTime,
                endTime: endTime,
                isCurrentClass: true,
                isSelfStudy: false
            )

            return WidgetEntry(
                date: now,
                state: .hasClasses,
                classData: sampleClass,
                upcomingClasses: [],
                configuration: configuration
            )
        }

        // Otherwise, return real data
        return await getTimelineEntry(for: configuration)
    }

    // Timeline implementation is now in the extension in WidgetModels.swift
}

struct OutspireWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

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
                case let .holiday(endDate):
                    holidayView(endDate: endDate)
                case .noClasses:
                    noClassesView
                case .hasClasses:
                    if let classData = entry.currentClassData {
                        classView(classData: classData)
                    } else {
                        noClassesView
                    }
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

    // MARK: - Class View

    private var showLargeWidgetUpcomingClasses: Bool {
        widgetFamily == .systemLarge && !entry.upcomingClasses.isEmpty
    }

    private var showCountdown: Bool {
        entry.configuration.showCountdown
    }

    private var showTimeBadge: Bool {
        widgetFamily != .systemSmall
    }

    private var showDetailLabels: Bool {
        widgetFamily != .systemSmall || !showCountdown
    }

    private var isSmallWidget: Bool {
        widgetFamily == .systemSmall
    }

    private func classView(classData: ClassWidgetData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - more compact with reduced padding
            HStack {
                VStack(alignment: .leading, spacing: isSmallWidget ? 0 : 1) {
                    Text(classData.statusText)
                        .font(isSmallWidget ? .caption2 : .caption)
                        .fontWeight(.medium)
                        .foregroundStyle(classColor(for: classData))

                    Text("Period \(classData.periodNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Only show time range badge in medium and larger widgets
                if showTimeBadge {
                    Text(classData.timeRangeFormatted)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(classColor(for: classData).opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, isSmallWidget ? 6 : 8)
            .padding(.bottom, isSmallWidget ? 3 : 4)

            // Class details - more compact layout
            VStack(alignment: .leading, spacing: isSmallWidget ? 1 : 2) {
                Text(classData.className)
                    .font(isSmallWidget ? .callout : .system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                if showDetailLabels {
                    HStack(spacing: 8) {
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
                    }
                    .foregroundStyle(.secondary)
                } else if isSmallWidget && showCountdown {
                    // For small widgets with countdown, show compact info
                    if !classData.teacherName.isEmpty || !classData.roomNumber.isEmpty {
                        let hasTeacher = !classData.teacherName.isEmpty
                        let hasRoom = !classData.roomNumber.isEmpty
                        let separator = hasTeacher && hasRoom ? " • " : ""

                        Text("\(classData.teacherName)\(separator)\(classData.roomNumber)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.85)
                    }
                }
            }
            .padding(.horizontal, 12)

            // Compact countdown section
            if showCountdown {
                Spacer(minLength: isSmallWidget ? 1 : 3)

                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 12)

                    HStack(alignment: .center) {
                        // Timer icon - smaller for small widget
                        Image(systemName: classData.isCurrentClass ? "timer" : "hourglass")
                            .font(.system(size: isSmallWidget ? 11 : 13, weight: .medium))
                            .foregroundStyle(classColor(for: classData))
                            .frame(
                                width: isSmallWidget ? 16 : 20,
                                height: isSmallWidget ? 16 : 20
                            )
                            .background(
                                Circle()
                                    .fill(classColor(for: classData).opacity(0.1))
                            )

                        // Timer label and countdown - more compact
                        VStack(alignment: .leading, spacing: 0) {
                            Text(classData.isCurrentClass ? "Ends in" : "Starts in")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            if isSmallWidget {
                                // More compact timer for small widget
                                Text(classData.targetDate, style: .timer)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(classColor(for: classData))
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            } else {
                                // Regular timer for medium widget
                                Text(classData.targetDate, style: .timer)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(classColor(for: classData))
                                    .monospacedDigit()
                            }
                        }

                        Spacer()

                        // Progress circle - only for current class and medium+ widgets
                        if classData.isCurrentClass && widgetFamily != .systemSmall {
                            ZStack {
                                ProgressView(
                                    timerInterval: classData.progressRange,
                                    countsDown: false,
                                    label: { EmptyView() },
                                    currentValueLabel: { EmptyView() }
                                )
                                .progressViewStyle(.circular)
                                .frame(width: 22, height: 22)
                                .tint(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, isSmallWidget ? 3 : 5)
                }
            } else {
                // When not showing countdown, add minimal spacing
                Spacer(minLength: 0)
            }

            // For large widget, show upcoming classes more compactly
            if showLargeWidgetUpcomingClasses {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.horizontal, 12)

                    HStack {
                        Text("Upcoming Classes")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .padding(.bottom, 2)

                    ForEach(entry.upcomingClasses.prefix(3), id: \.periodNumber) { upcomingClass in
                        upcomingClassRow(upcomingClass)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // Row for upcoming classes in large widget
    private func upcomingClassRow(_ classData: ClassWidgetData) -> some View {
        HStack(spacing: 4) {
            // Period indicator
            Text("P\(classData.periodNumber)")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    Capsule()
                        .fill(classColor(for: classData).opacity(0.1))
                )
                .foregroundStyle(classColor(for: classData))

            // Class name
            Text(classData.className)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Spacer()

            // Time
            Text(classData.timeRangeFormatted)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }

    // MARK: - Helper Methods

    private func classColor(for classData: ClassWidgetData) -> Color {
        if classData.isSelfStudy {
            return .purple
        } else {
            // Use the same color scheme as in ClasstableView
            return WidgetHelpers.getSubjectColor(from: classData.className)
        }
    }

    // MARK: - Accessory Views

    // Accessory inline view - shows minimal info with countdown
    private func accessoryInlineView(entry: Provider.Entry) -> some View {
        Group {
            if case .hasClasses = entry.state, let classData = entry.currentClassData {
                // Show class name and countdown in an HStack instead of using Text + Text
                HStack(spacing: 2) {
                    Text("\(classData.className):")
                    Text(classData.targetDate, style: .timer)
                        .monospacedDigit()
                }
                .lineLimit(1)
            } else {
                // Default state
                Text("No classes")
                    .lineLimit(1)
            }
        }
    }

    // Accessory rectangular view - shows countdown
    private func accessoryRectangularView(entry: Provider.Entry) -> some View {
        Group {
            if case .hasClasses = entry.state, let classData = entry.currentClassData {
                VStack(alignment: .leading, spacing: 2) {
                    // Class name
                    Text(classData.className)
                        .font(.headline)
                        .lineLimit(1)

                    // Countdown with label
                    HStack {
                        Text(classData.isCurrentClass ? "Ends in:" : "Starts in:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(classData.targetDate, style: .timer)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Default state - ensure same spacing as above
                VStack(alignment: .leading, spacing: 2) {
                    Text("No classes")
                        .font(.headline)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: 2.5
                )

            // Progress indicator
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.orange,
                    style: StrokeStyle(
                        lineWidth: 2.5,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Widget Configuration

struct OutspireWidget: Widget {
    let kind: String = "OutspireWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ClassWidgetConfigurationIntent.self, provider: Provider()) { entry in
            OutspireWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Class Widget")
        .description("View your current or upcoming class with countdown.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

private extension ClassWidgetConfigurationIntent {
    static var withCountdown: ClassWidgetConfigurationIntent {
        let intent = ClassWidgetConfigurationIntent()
        intent.showCountdown = true
        return intent
    }

    static var withoutCountdown: ClassWidgetConfigurationIntent {
        let intent = ClassWidgetConfigurationIntent()
        intent.showCountdown = false
        return intent
    }
}

#Preview(as: .systemSmall) {
    OutspireWidget()
} timeline: {
    // Create sample data for preview
    let calendar = Calendar.current
    let now = Date()
    let startTime = calendar.date(bySettingHour: 10, minute: 45, second: 0, of: now)!
    let endTime = calendar.date(bySettingHour: 11, minute: 25, second: 0, of: now)!

    let sampleClass = ClassWidgetData(
        className: "Mathematics",
        teacherName: "Mr. Smith",
        roomNumber: "A101",
        periodNumber: 4,
        startTime: startTime,
        endTime: endTime,
        isCurrentClass: true,
        isSelfStudy: false
    )

    WidgetEntry(
        date: now,
        state: .hasClasses,
        classData: sampleClass,
        upcomingClasses: [],
        configuration: .withCountdown
    )
}

#Preview(as: .systemMedium) {
    OutspireWidget()
} timeline: {
    // Create sample data for preview
    let calendar = Calendar.current
    let now = Date()
    let startTime = calendar.date(bySettingHour: 10, minute: 45, second: 0, of: now)!
    let endTime = calendar.date(bySettingHour: 11, minute: 25, second: 0, of: now)!

    let sampleClass = ClassWidgetData(
        className: "Mathematics",
        teacherName: "Mr. Smith",
        roomNumber: "A101",
        periodNumber: 4,
        startTime: startTime,
        endTime: endTime,
        isCurrentClass: true,
        isSelfStudy: false
    )

    WidgetEntry(
        date: now,
        state: .hasClasses,
        classData: sampleClass,
        upcomingClasses: [],
        configuration: .withCountdown
    )
}
