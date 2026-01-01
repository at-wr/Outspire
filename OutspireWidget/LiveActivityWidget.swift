import WidgetKit
import SwiftUI

#if !targetEnvironment(macCatalyst)
import ActivityKit

struct ClassActivityAttributes: ActivityAttributes {
    public struct ScheduledClass: Codable, Hashable, Identifiable {
        public let id: UUID
        public let className: String
        public let teacherName: String
        public let roomNumber: String
        public let periodNumber: Int
        public let startTime: Date
        public let endTime: Date
    }

    public struct ContentState: Codable, Hashable {
        var schedule: [ScheduledClass]
        var generatedAt: Date
        var finalEndDate: Date
    }

    var className: String
    var roomNumber: String
    var teacherName: String

    enum ClassStatus: String, Codable {
        case upcoming
        case ongoing
        case ending
        case completed
    }

    static var preview: ClassActivityAttributes {
        ClassActivityAttributes(
            className: "Mathematics",
            roomNumber: "A203",
            teacherName: "Mr. Smith"
        )
    }
}

private struct ClassActivityDerivedState {
    let date: Date
    let schedule: [ClassActivityAttributes.ScheduledClass]
    let current: ClassActivityAttributes.ScheduledClass?
    let next: ClassActivityAttributes.ScheduledClass?
    let status: ClassActivityAttributes.ClassStatus
    let countdownTarget: Date?
    let timeRemaining: TimeInterval
    let progress: Double

    init(context: ActivityViewContext<ClassActivityAttributes>, date: Date) {
        self.date = date
        let sorted = context.state.schedule.sorted(by: { $0.startTime < $1.startTime })
        schedule = sorted

        let now = date
        let active = sorted.first(where: { $0.startTime <= now && $0.endTime > now })
        let upcoming = sorted.first(where: { $0.startTime > now })

        current = active
        next = upcoming

        if let active = active {
            let remaining = active.endTime.timeIntervalSince(now)
            let total = active.endTime.timeIntervalSince(active.startTime)
            timeRemaining = max(remaining, 0)
            countdownTarget = active.endTime
            progress = total > 0 ? max(0, min(1, now.timeIntervalSince(active.startTime) / total)) : 1
            status = remaining <= 300 ? .ending : .ongoing
        } else if let upcoming = upcoming {
            let remaining = upcoming.startTime.timeIntervalSince(now)
            timeRemaining = max(remaining, 0)
            countdownTarget = upcoming.startTime
            progress = 0
            status = .upcoming
        } else {
            timeRemaining = 0
            countdownTarget = nil
            progress = 1
            status = .completed
        }
    }

    var displayClass: ClassActivityAttributes.ScheduledClass? {
        current ?? next
    }
}

private struct ClassActivityTimelineView<Content: View>: View {
    let context: ActivityViewContext<ClassActivityAttributes>
    let refreshInterval: TimeInterval
    let content: (ClassActivityDerivedState) -> Content

    init(
        context: ActivityViewContext<ClassActivityAttributes>,
        refreshInterval: TimeInterval = 10,
        @ViewBuilder content: @escaping (ClassActivityDerivedState) -> Content
    ) {
        self.context = context
        self.refreshInterval = refreshInterval
        self.content = content
    }

    var body: some View {
        TimelineView(.periodic(from: Date(), by: refreshInterval)) { timelineContext in
            let derivedState = ClassActivityDerivedState(context: context, date: timelineContext.date)
            content(derivedState)
        }
    }
}

struct OutspireWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClassActivityAttributes.self) { context in
            ClassActivityTimelineView(context: context) { derivedState in
                LockScreenView(state: derivedState)
                    .activityBackgroundTint(Color(.secondarySystemBackground))
                    .activitySystemActionForegroundColor(.primary)
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ClassActivityTimelineView(context: context) { derivedState in
                        DynamicIslandLeadingView(state: derivedState)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ClassActivityTimelineView(context: context) { derivedState in
                        DynamicIslandTrailingView(state: derivedState)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ClassActivityTimelineView(context: context) { derivedState in
                        DynamicIslandBottomView(state: derivedState)
                    }
                }
            } compactLeading: {
                ClassActivityTimelineView(context: context) { derivedState in
                    CompactLeadingView(state: derivedState)
                }
            } compactTrailing: {
                ClassActivityTimelineView(context: context) { derivedState in
                    CompactTrailingView(state: derivedState)
                }
            } minimal: {
                ClassActivityTimelineView(context: context) { derivedState in
                    MinimalView(state: derivedState)
                }
            }
            .widgetURL(URL(string: "outspire://today"))
            .keylineTint(statusColor(for: ClassActivityDerivedState(context: context, date: Date()).status))
        }
    }
}

// MARK: - Views

private struct LockScreenView: View {
    let state: ClassActivityDerivedState

    var body: some View {
        HStack(spacing: 12) {
            if let displayClass = state.displayClass {
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.status == .upcoming ? "Next Class" : state.status == .completed ? "All Done" : "Current Class")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(classColor(for: state))

                    Text(displayClass.className)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    HStack(spacing: 16) {
                        if !displayClass.roomNumber.isEmpty {
                            Label(displayClass.roomNumber, systemImage: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !displayClass.teacherName.isEmpty {
                            Label(displayClass.teacherName, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text("No classes scheduled")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(state.displayClass?.periodNumber.map { "#\($0)" } ?? "--")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(countdownLabel(for: state.status))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let target = state.countdownTarget, state.status != .completed {
                    timerText(target: target)
                } else {
                    Text("Done")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                if state.status == .ongoing || state.status == .ending,
                    let active = state.current
                {
                    ProgressView(
                        timerInterval: active.startTime...active.endTime,
                        countsDown: false,
                        label: { EmptyView() },
                        currentValueLabel: { EmptyView() }
                    )
                    .progressViewStyle(.linear)
                    .frame(width: 70)
                    .tint(classColor(for: state))
                }
            }
            .frame(width: 100)
        }
        .padding()
    }

    @ViewBuilder
    private func timerText(target: Date) -> some View {
        Text("00:00")
            .hidden()
            .overlay(alignment: .trailing) {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .frame(width: 80, alignment: .trailing)
                    .foregroundStyle(classColor(for: state))
            }
    }
}

private struct DynamicIslandLeadingView: View {
    let state: ClassActivityDerivedState

    var body: some View {
        if let displayClass = state.displayClass {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayClass.periodNumber > 0 ? "# \(displayClass.periodNumber)" : "--")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(displayClass.className)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .padding(.leading, 4)
        } else {
            Text("No Classes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct DynamicIslandTrailingView: View {
    let state: ClassActivityDerivedState

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(countdownLabel(for: state.status))
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let target = state.countdownTarget, state.status != .completed {
                Text("00:00")
                    .hidden()
                    .overlay(alignment: .leading) {
                        Text(timerInterval: Date.now...target, countsDown: true)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .frame(width: 80, alignment: .trailing)
                            .foregroundStyle(classColor(for: state))
                    }
            } else {
                Text("Done")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.trailing, 4)
    }
}

private struct DynamicIslandBottomView: View {
    let state: ClassActivityDerivedState

    var body: some View {
        HStack {
            if let displayClass = state.displayClass {
                if !displayClass.roomNumber.isEmpty {
                    Label(displayClass.roomNumber, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !displayClass.teacherName.isEmpty {
                    Label(displayClass.teacherName, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if state.status == .ongoing || state.status == .ending,
                let active = state.current
            {
                ProgressView(
                    timerInterval: active.startTime...active.endTime,
                    countsDown: false,
                    label: { EmptyView() },
                    currentValueLabel: { EmptyView() }
                )
                .progressViewStyle(.linear)
                .frame(width: 60)
                .tint(classColor(for: state))
            }
        }
    }
}

private struct CompactLeadingView: View {
    let state: ClassActivityDerivedState

    var body: some View {
        ZStack {
            if state.status == .ongoing || state.status == .ending,
                let active = state.current
            {
                ProgressView(
                    timerInterval: active.startTime...active.endTime,
                    countsDown: false,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: "star.fill")
                            .foregroundStyle(classColor(for: state))
                    }
                )
                .progressViewStyle(.circular)
                .tint(classColor(for: state))
            } else if state.status == .upcoming {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(classColor(for: state))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
    }
}

private struct CompactTrailingView: View {
    let state: ClassActivityDerivedState

    var body: some View {
        if let target = state.countdownTarget, state.status != .completed {
            Text("00:00")
                .hidden()
                .overlay(alignment: .leading) {
                    Text(timerInterval: Date.now...target, countsDown: true)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .frame(width: 60, alignment: .trailing)
                        .foregroundStyle(classColor(for: state))
                }
        } else {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct MinimalView: View {
    let state: ClassActivityDerivedState

    var body: some View {
        if state.status == .ongoing || state.status == .ending,
            let active = state.current
        {
            ProgressView(
                timerInterval: active.startTime...active.endTime,
                countsDown: false,
                label: { EmptyView() },
                currentValueLabel: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(classColor(for: state))
                }
            )
            .progressViewStyle(.circular)
            .tint(statusColor(for: state.status))
        } else if state.status == .upcoming {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(classColor(for: state))
        } else {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Helpers

private func countdownLabel(for status: ClassActivityAttributes.ClassStatus) -> String {
    switch status {
    case .upcoming:
        return "Starts in"
    case .ongoing, .ending:
        return "Ends in"
    case .completed:
        return "Completed"
    }
}

private func classColor(for state: ClassActivityDerivedState) -> Color {
    guard let displayClass = state.displayClass else { return .blue }
    let subject = displayClass.className.lowercased()
    if subject.contains("self-study") {
        return .purple
    }
    return WidgetHelpers.getSubjectColor(from: displayClass.className)
}

private func statusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
    switch status {
    case .upcoming:
        return .blue
    case .ongoing:
        return .green
    case .ending:
        return .orange
    case .completed:
        return .gray
    }
}

// MARK: - Preview support

extension ClassActivityAttributes.ScheduledClass {
    static func sample(
        periodNumber: Int,
        startOffset: TimeInterval,
        duration: TimeInterval,
        className: String,
        teacherName: String,
        roomNumber: String
    ) -> ClassActivityAttributes.ScheduledClass {
        let start = Date().addingTimeInterval(startOffset)
        return ClassActivityAttributes.ScheduledClass(
            id: UUID(),
            className: className,
            teacherName: teacherName,
            roomNumber: roomNumber,
            periodNumber: periodNumber,
            startTime: start,
            endTime: start.addingTimeInterval(duration)
        )
    }
}

extension ClassActivityAttributes.ContentState {
    static var previewState: ClassActivityAttributes.ContentState {
        let samples = [
            ClassActivityAttributes.ScheduledClass.sample(
                periodNumber: 3,
                startOffset: -900,
                duration: 1800,
                className: "Mathematics",
                teacherName: "Mr. Smith",
                roomNumber: "A203"
            ),
            ClassActivityAttributes.ScheduledClass.sample(
                periodNumber: 4,
                startOffset: 1800,
                duration: 1800,
                className: "Chemistry",
                teacherName: "Ms. Johnson",
                roomNumber: "Lab 2"
            )
        ]

        return ClassActivityAttributes.ContentState(
            schedule: samples,
            generatedAt: Date(),
            finalEndDate: samples.last?.endTime ?? Date()
        )
    }
}

extension Color {
    static var tint: Color { .blue }
}

#Preview("Notification", as: .content, using: ClassActivityAttributes.preview) {
    OutspireWidgetLiveActivity()
} contentStates: {
    ClassActivityAttributes.ContentState.previewState
}

#endif
