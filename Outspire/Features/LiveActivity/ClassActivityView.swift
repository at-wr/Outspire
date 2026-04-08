import SwiftUI
import WidgetKit

#if !targetEnvironment(macCatalyst)
    import ActivityKit

    private struct LiveActivityDerivedState {
        let date: Date
        let schedule: [ClassActivityAttributes.ScheduledClass]
        let current: ClassActivityAttributes.ScheduledClass?
        let next: ClassActivityAttributes.ScheduledClass?
        let status: ClassActivityAttributes.ClassStatus
        let countdownTarget: Date?
        let timeRemaining: TimeInterval

        init(context: ActivityViewContext<ClassActivityAttributes>, date: Date) {
            self.date = date
            let ordered = context.state.schedule.sorted(by: { $0.startTime < $1.startTime })
            schedule = ordered

            let now = date
            current = ordered.first(where: { $0.startTime <= now && $0.endTime > now })
            next = ordered.first(where: { $0.startTime > now })

            if let current = current {
                countdownTarget = current.endTime
                timeRemaining = max(current.endTime.timeIntervalSince(now), 0)
                status = timeRemaining <= 300 ? .ending : .ongoing
            } else if let next = next {
                countdownTarget = next.startTime
                timeRemaining = max(next.startTime.timeIntervalSince(now), 0)
                status = .upcoming
            } else {
                countdownTarget = nil
                timeRemaining = 0
                status = .completed
            }
        }

        var displayClass: ClassActivityAttributes.ScheduledClass? {
            current ?? next
        }
    }

    private func transitionDates(for state: ClassActivityAttributes.ContentState) -> [Date] {
        let now = Date()
        var dates = Set<Date>()
        for cls in state.schedule {
            dates.insert(cls.startTime)
            dates.insert(cls.endTime)
            dates.insert(cls.endTime.addingTimeInterval(-300))
        }
        let upcoming = dates.filter { $0 > now }.sorted()
        return upcoming.isEmpty ? [now] : upcoming
    }

    private struct LiveActivityTimeline<Content: View>: View {
        let context: ActivityViewContext<ClassActivityAttributes>
        let content: (LiveActivityDerivedState) -> Content

        init(
            context: ActivityViewContext<ClassActivityAttributes>,
            @ViewBuilder content: @escaping (LiveActivityDerivedState) -> Content
        ) {
            self.context = context
            self.content = content
        }

        var body: some View {
            TimelineView(.explicit(transitionDates(for: context.state))) { timeline in
                let derived = LiveActivityDerivedState(context: context, date: timeline.date)
                content(derived)
            }
        }
    }

    struct ClassActivityLiveActivity: Widget {
        var body: some WidgetConfiguration {
            ActivityConfiguration(for: ClassActivityAttributes.self) { context in
                LiveActivityTimeline(context: context) { derived in
                    LockScreenActivityView(state: derived)
                        .activityBackgroundTint(Color(.secondarySystemBackground))
                        .activitySystemActionForegroundColor(.primary)
                }
            } dynamicIsland: { context in
                DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        LiveActivityTimeline(context: context) { derived in
                            LeadingActivityView(state: derived)
                        }
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        LiveActivityTimeline(context: context) { derived in
                            TrailingActivityView(state: derived)
                        }
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        LiveActivityTimeline(context: context) { derived in
                            BottomActivityView(state: derived)
                        }
                    }
                } compactLeading: {
                    LiveActivityTimeline(context: context) { derived in
                        CompactLeadingActivityView(state: derived)
                    }
                } compactTrailing: {
                    LiveActivityTimeline(context: context) { derived in
                        CompactTrailingActivityView(state: derived)
                    }
                } minimal: {
                    LiveActivityTimeline(context: context) { derived in
                        MinimalActivityView(state: derived)
                    }
                }
                .widgetURL(URL(string: "outspire://today"))
                .keylineTint(activityStatusColor(for: LiveActivityDerivedState(context: context, date: Date()).status))
            }
        }
    }

    // MARK: - Views

    private struct LockScreenActivityView: View {
        let state: LiveActivityDerivedState

        var body: some View {
            HStack(spacing: 12) {
                if let display = state.displayClass {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headerTitle)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(activityClassColor(for: state))

                        Text(display.className)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        HStack(spacing: 16) {
                            if !display.roomNumber.isEmpty {
                                Label(display.roomNumber, systemImage: "mappin.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !display.teacherName.isEmpty {
                                Label(display.teacherName, systemImage: "person.fill")
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
                    Text(state.displayClass.map { "#\($0)" } ?? "--")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(activityCountdownLabel(for: state.status))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let target = state.countdownTarget, state.status != .completed {
                        Text("00:00")
                            .hidden()
                            .overlay(alignment: .trailing) {
                                Text(timerInterval: Date.now ... target, countsDown: true)
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                    .frame(width: 80, alignment: .trailing)
                                    .foregroundStyle(activityClassColor(for: state))
                            }
                    } else {
                        Text("Done")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    if (state.status == .ongoing || state.status == .ending),
                       let active = state.current,
                       active.endTime > state.date
                    {
                        ProgressView(
                            timerInterval: active.startTime ... active.endTime,
                            countsDown: false,
                            label: { EmptyView() },
                            currentValueLabel: { EmptyView() }
                        )
                        .progressViewStyle(.linear)
                        .frame(width: 70)
                        .tint(activityClassColor(for: state))
                    }
                }
                .frame(width: 100)
            }
            .padding()
        }

        private var headerTitle: String {
            switch state.status {
            case .upcoming:
                return "Next Class"
            case .ongoing, .ending:
                return "Current Class"
            case .completed:
                return "All Done"
            }
        }
    }

    private struct LeadingActivityView: View {
        let state: LiveActivityDerivedState

        var body: some View {
            if let display = state.displayClass {
                VStack(alignment: .leading, spacing: 2) {
                    Text(display.periodNumber > 0 ? "# \(display.periodNumber)" : "--")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(display.className)
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

    private struct TrailingActivityView: View {
        let state: LiveActivityDerivedState

        var body: some View {
            VStack(alignment: .trailing, spacing: 2) {
                Text(activityCountdownLabel(for: state.status))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let target = state.countdownTarget, state.status != .completed {
                    Text("00:00")
                        .hidden()
                        .overlay(alignment: .leading) {
                            Text(timerInterval: Date.now ... target, countsDown: true)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .frame(width: 80, alignment: .trailing)
                                .foregroundStyle(activityClassColor(for: state))
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

    private struct BottomActivityView: View {
        let state: LiveActivityDerivedState

        var body: some View {
            HStack {
                if let display = state.displayClass {
                    if !display.roomNumber.isEmpty {
                        Label(display.roomNumber, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !display.teacherName.isEmpty {
                        Label(display.teacherName, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if (state.status == .ongoing || state.status == .ending),
                   let active = state.current,
                   active.endTime > state.date
                {
                    ProgressView(
                        timerInterval: active.startTime ... active.endTime,
                        countsDown: false,
                        label: { EmptyView() },
                        currentValueLabel: { EmptyView() }
                    )
                    .progressViewStyle(.linear)
                    .frame(width: 60)
                    .tint(activityClassColor(for: state))
                }
            }
        }
    }

    private struct CompactLeadingActivityView: View {
        let state: LiveActivityDerivedState

        var body: some View {
            ZStack {
                if (state.status == .ongoing || state.status == .ending),
                   let active = state.current,
                   active.endTime > state.date
                {
                    ProgressView(
                        timerInterval: active.startTime ... active.endTime,
                        countsDown: false,
                        label: { EmptyView() },
                        currentValueLabel: {
                            Image(systemName: "star.fill")
                                .foregroundStyle(activityClassColor(for: state))
                        }
                    )
                    .progressViewStyle(.circular)
                    .tint(activityClassColor(for: state))
                } else if state.status == .upcoming {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(activityClassColor(for: state))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private struct CompactTrailingActivityView: View {
        let state: LiveActivityDerivedState

        var body: some View {
            if let target = state.countdownTarget, state.status != .completed {
                Text("00:00")
                    .hidden()
                    .overlay(alignment: .leading) {
                        Text(timerInterval: Date.now ... target, countsDown: true)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .frame(width: 60, alignment: .trailing)
                            .foregroundStyle(activityClassColor(for: state))
                    }
            } else {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private struct MinimalActivityView: View {
        let state: LiveActivityDerivedState

        var body: some View {
            if (state.status == .ongoing || state.status == .ending),
               let active = state.current,
               active.endTime > state.date
            {
                ProgressView(
                    timerInterval: active.startTime ... active.endTime,
                    countsDown: false,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: "star.fill")
                            .foregroundStyle(activityClassColor(for: state))
                    }
                )
                .progressViewStyle(.circular)
                .tint(activityStatusColor(for: state.status))
            } else if state.status == .upcoming {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(activityClassColor(for: state))
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Helpers

    private func activityCountdownLabel(for status: ClassActivityAttributes.ClassStatus) -> String {
        switch status {
        case .upcoming:
            return "Starts in"
        case .ongoing, .ending:
            return "Ends in"
        case .completed:
            return "Completed"
        }
    }

    private func activityStatusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
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

    private func activityClassColor(for state: LiveActivityDerivedState) -> Color {
        guard let display = state.displayClass else { return .blue }
        let lowered = display.className.lowercased()

        if lowered.contains("self-study") {
            return .purple
        }

        let colorMap: [Color: [String]] = [
            .blue: ["math", "mathematics", "maths"],
            .green: ["english", "language", "literature", "general paper", "esl"],
            .orange: ["physics", "science"],
            .purple: ["chemistry", "chem"],
            .teal: ["biology", "bio"],
            .mint: ["further math", "maths further"],
            .yellow: ["体育", "pe", "sports", "p.e"],
            .pink: ["economics", "econ"],
            .cyan: ["arts", "art", "tok"],
            .indigo: ["chinese", "mandarin", "语文"],
            .gray: ["history", "历史", "geography", "geo", "政治"]
        ]

        for (color, keywords) in colorMap {
            if keywords.contains(where: { lowered.contains($0.lowercased()) }) {
                return color
            }
        }

        return .blue
    }

#endif
