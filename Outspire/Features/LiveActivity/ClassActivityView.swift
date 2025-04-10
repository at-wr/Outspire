import SwiftUI
import WidgetKit

#if !targetEnvironment(macCatalyst)
import ActivityKit

struct ClassActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClassActivityAttributes.self) { context in
            ClassActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ClassLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ClassTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ClassBottomView(context: context)
                }
            } compactLeading: {
                ZStack {
                    Circle()
                        .fill(statusColor(for: context.state.currentStatus))
                    Text("\(context.state.periodNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(3)
            } compactTrailing: {
                Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
                    .font(.caption2)
                    .fontWeight(.bold)
                    .frame(width: 40)
            } minimal: {
                ZStack {
                    Circle()
                        .fill(statusColor(for: context.state.currentStatus))
                    Text("\(context.state.periodNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .widgetURL(URL(string: "outspire://today"))
            .keylineTint(statusColor(for: context.state.currentStatus))
        }
    }

    private func statusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
        switch status {
        case .upcoming:
            return .blue
        case .ongoing:
            return .green
        case .ending:
            return .orange
        }
    }
}

struct ClassActivityLockScreenView: View {
    let context: ActivityViewContext<ClassActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header with status and period number
            HStack {
                statusBadge

                Spacer()

                Text("Period \(context.attributes.className)")
                    .font(.headline)
                    .lineLimit(1)
            }
            .padding(.bottom, 2)

            // Middle content - time info
            HStack(alignment: .center) {
                // Time countdown
                if context.state.currentStatus == .upcoming {
                    Text("Starts in:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Ends in:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                    .font(.system(.title2, design: .rounded).monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor(for: context.state.currentStatus))

                Spacer()

                // Room display
                HStack(spacing: 2) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text(context.attributes.roomNumber)
                        .font(.subheadline)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
            }

            // Bottom info - teacher and time range
            HStack {
                VStack(alignment: .leading) {
                    // Teacher name
                    HStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.attributes.teacherName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Time display
                    HStack(spacing: 2) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        // Fix: Use a computed property instead of configuring formatters directly in the view
                        Text(formattedTimeRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // School logo or icon
                Image(systemName: "building.columns")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.indigo)
            }
        }
        .padding(16)
        .background {
            ContainerRelativeShape()
                .fill(.ultraThinMaterial)
        }
    }

    // Fix: Add computed property to format the time range
    private var formattedTimeRange: String {
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "HH:mm"

        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "HH:mm"

        return "\(startFormatter.string(from: context.state.startTime)) - \(endFormatter.string(from: context.state.endTime))"
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch context.state.currentStatus {
        case .upcoming:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                Text("Upcoming")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.blue)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())

        case .ongoing:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text("In Progress")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())

        case .ending:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)
                Text("Ending Soon")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // Add the missing statusColor function
    private func statusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
        switch status {
        case .upcoming: return .blue
        case .ongoing: return .green
        case .ending: return .orange
        }
    }
}

// Dynamic Island expanded components
struct ClassLeadingView: View {
    let context: ActivityViewContext<ClassActivityAttributes>

    var body: some View {
        VStack(alignment: .leading) {
            Text(context.attributes.className)
                .font(.headline)
                .lineLimit(1)

            Text(context.attributes.teacherName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.leading)
    }
}

struct ClassTrailingView: View {
    let context: ActivityViewContext<ClassActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing) {
            // Status text
            Text(context.state.currentStatus == .upcoming ? "Upcoming" : "In Progress")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(statusColor(for: context.state.currentStatus))

            // Room number
            Text("Room \(context.attributes.roomNumber)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.trailing)
    }

    private func statusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
        switch status {
        case .upcoming: return .blue
        case .ongoing: return .green
        case .ending: return .orange
        }
    }
}

struct ClassBottomView: View {
    let context: ActivityViewContext<ClassActivityAttributes>

    var body: some View {
        HStack {
            // Start time
            VStack(alignment: .leading) {
                Text("Starts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Fixed: Move DateFormatter configuration outside view body
                Text(formattedStartTime)
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Countdown timer
            VStack {
                Text(context.state.currentStatus == .upcoming ? "Starting in:" : "Ending in:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                    .font(.system(.headline, design: .rounded).monospacedDigit())
                    .fontWeight(.bold)
                    .foregroundColor(statusColor(for: context.state.currentStatus))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            // End time
            VStack(alignment: .trailing) {
                Text("Ends")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Fixed: Move DateFormatter configuration outside view body
                Text(formattedEndTime)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding([.horizontal, .bottom])
    }

    // Add the missing statusColor function
    private func statusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
        switch status {
        case .upcoming: return .blue
        case .ongoing: return .green
        case .ending: return .orange
        }
    }

    // Add computed properties for formatted times
    private var formattedStartTime: String {
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "HH:mm"
        return startFormatter.string(from: context.state.startTime)
    }

    private var formattedEndTime: String {
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "HH:mm"
        return endFormatter.string(from: context.state.endTime)
    }
}
#endif
