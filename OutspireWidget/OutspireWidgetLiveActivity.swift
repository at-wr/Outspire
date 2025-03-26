//
//  OutspireWidgetLiveActivity.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import WidgetKit
import SwiftUI

#if !targetEnvironment(macCatalyst)
import ActivityKit

// ClassActivityAttributes remains unchanged
struct ClassActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var endTime: Date
        var currentStatus: ClassStatus
        var periodNumber: Int
        var progress: Double
        var timeRemaining: TimeInterval
    }
    
    var className: String
    var roomNumber: String
    var teacherName: String
    
    enum ClassStatus: String, Codable {
        case upcoming
        case ongoing
        case ending
    }
    
    static var preview: ClassActivityAttributes {
        ClassActivityAttributes(
            className: "Mathematics",
            roomNumber: "A203",
            teacherName: "Mr. Smith"
        )
    }
}

struct OutspireWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClassActivityAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenView(context: context)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("# \(context.state.periodNumber)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(context.attributes.className)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.currentStatus == .upcoming ? "Starts in" : "Ends in")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("00:00") // Placeholder to stabilize layout
                            .hidden() // Hide the placeholder
                            .overlay(alignment: .leading) {
                                // Use different time interval based on status
                                if context.state.currentStatus == .upcoming {
                                    Text(timerInterval: Date.now...context.state.startTime, countsDown: true)
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.9)
                                        .frame(width: 80, alignment: .trailing) // Fixed width to match max timer string
                                        .foregroundStyle(classColor(for: context))
                                } else {
                                    Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.9)
                                        .frame(width: 80, alignment: .trailing) // Fixed width to match max timer string
                                        .foregroundStyle(classColor(for: context))
                                }
                            }
                    }
                    .padding(.trailing, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if !context.attributes.roomNumber.isEmpty {
                            Label {
                                Text(context.attributes.roomNumber)
                            } icon: {
                                Image(systemName: "mappin")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        
                        if !context.attributes.teacherName.isEmpty {
                            Label {
                                Text(context.attributes.teacherName)
                            } icon: {
                                Image(systemName: "person.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Progress indicator without percentage text
                        if context.state.currentStatus != .upcoming {
                            // Replace static progress view with timer-based one
                            ProgressView(
                                timerInterval: context.state.startTime...context.state.endTime,
                                countsDown: false,
                                label: { EmptyView() },
                                currentValueLabel: { EmptyView() }
                            )
                            .progressViewStyle(.linear)
                            .frame(width: 60)
                            .tint(classColor(for: context))
                        }
                    }
                }
            } compactLeading: {
                ZStack {
                    // Use timer-based progress for smooth animation
                    if context.state.currentStatus != .upcoming {
                        ProgressView(
                            timerInterval: context.state.startTime...context.state.endTime,
                            countsDown: false,
                            label: { EmptyView() },
                            currentValueLabel: {
                                Image(systemName: "star.fill")
                                    //.font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(classColor(for: context))
                            }
                        )
                        .progressViewStyle(.circular)
                        .tint(classColor(for: context))
                    } else {
                        // For upcoming class, just show the star
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.tint)
                    }
                }
            } compactTrailing: {
                Text("00:00") // Placeholder to stabilize layout
                    .hidden() // Hide the placeholder
                    .overlay(alignment: .leading) {
                        // Use different time interval based on status
                        if context.state.currentStatus == .upcoming {
                            Text(timerInterval: Date.now...context.state.startTime, countsDown: true)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .frame(width: 80, alignment: .trailing) // Fixed width to match max timer string
                                .foregroundStyle(classColor(for: context))
                        } else {
                            Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .frame(width: 80, alignment: .trailing) // Fixed width to match max timer string
                                .foregroundStyle(classColor(for: context))
                        }
                    }
            } minimal: {
                // Replace text with progress view containing star
                ZStack {
                    // Use timer-based progress for smooth animation
                    if context.state.currentStatus != .upcoming {
                        ProgressView(
                            timerInterval: context.state.startTime...context.state.endTime,
                            countsDown: false,
                            label: { EmptyView() },
                            currentValueLabel: {
                                Image(systemName: "star.fill")
                                    //.font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(classColor(for: context))
                            }
                        )
                        .progressViewStyle(.circular)
                        .tint(statusColor(for: context.state.currentStatus))
                    } else {
                        // For upcoming class, just show the star
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.tint)
                    }
                }
            }
            .widgetURL(URL(string: "outspire://today"))
            .keylineTint(statusColor(for: context.state.currentStatus))
        }
    }
    
    // Helper functions remain unchanged
    private func formatTimeRemaining(_ timeInterval: TimeInterval, compact: Bool = false) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if compact {
            if hours > 0 {
                return "\(hours):\(String(format: "%02d", minutes))"
            } else {
                return "\(minutes):\(String(format: "%02d", seconds))"
            }
        } else {
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        }
    }
    
    // New method to get color based on class name, matching widget colors
    private func classColor(for context: ActivityViewContext<ClassActivityAttributes>) -> Color {
        let isSelfStudy = context.attributes.className.lowercased().contains("self-study")
        
        if isSelfStudy {
            return .purple
        } else {
            return WidgetHelpers.getSubjectColor(from: context.attributes.className)
        }
    }
    
    // Modified to include status as fallback
    private func statusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
        switch status {
        case .upcoming: return .blue
        case .ongoing: return .green
        case .ending: return .orange
        }
    }
}

// Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<ClassActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side with class info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.currentStatus == .upcoming ? "Next Class" : "Current Class")
                    .font(.caption2)
                    .fontWeight(.medium)
                    // Use classColor instead of statusColor
                    .foregroundStyle(classColor(for: context))
                
                Text(context.attributes.className)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack(spacing: 16) {
                    if !context.attributes.roomNumber.isEmpty {
                        Label {
                            Text(context.attributes.roomNumber)
                        } icon: {
                            Image(systemName: "mappin.circle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    if !context.attributes.teacherName.isEmpty {
                        Label {
                            Text(context.attributes.teacherName)
                        } icon: {
                            Image(systemName: "person.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Right side with period and timer
            VStack(alignment: .trailing, spacing: 2) {
                Text("#\(context.state.periodNumber)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(context.state.currentStatus == .upcoming ? "Starts in" : "Ends in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("00:00") // Placeholder to stabilize layout
                    .hidden() // Hide the placeholder
                    .overlay(alignment: .leading) {
                        // Use different time interval based on status
                        if context.state.currentStatus == .upcoming {
                            Text(timerInterval: Date.now...context.state.startTime, countsDown: true)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .frame(width: 80, alignment: .trailing) // Fixed width to match max timer string
                                .foregroundStyle(classColor(for: context))
                        } else {
                            Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .frame(width: 80, alignment: .trailing) // Fixed width to match max timer string
                                .foregroundStyle(classColor(for: context))
                        }
                    }
                
                if context.state.currentStatus != .upcoming {
                    // Replace static progress view with timer-based one and use classColor
                    ProgressView(
                        timerInterval: context.state.startTime...context.state.endTime,
                        countsDown: false,
                        label: { EmptyView() },
                        currentValueLabel: { EmptyView() }
                    )
                    .progressViewStyle(.linear)
                    .frame(width: 60)
                    .tint(classColor(for: context))
                }
            }
            .frame(width: 100)
        }
        .padding()
        .activityBackgroundTint(Color(.secondarySystemBackground))
        .activitySystemActionForegroundColor(.primary)
    }
    
    // Helper methods
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    // Add class color helper matching the widget
    private func classColor(for context: ActivityViewContext<ClassActivityAttributes>) -> Color {
        let isSelfStudy = context.attributes.className.lowercased().contains("self-study")
        
        if isSelfStudy {
            return .purple
        } else {
            return WidgetHelpers.getSubjectColor(from: context.attributes.className)
        }
    }
    
    // Keep statusColor as fallback
    private func statusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
        switch status {
        case .upcoming: return .blue
        case .ongoing: return .green
        case .ending: return .orange
        }
    }
}

// Preview code remains unchanged
extension ClassActivityAttributes.ContentState {
    static var current: ClassActivityAttributes.ContentState {
        ClassActivityAttributes.ContentState(
            startTime: Date().addingTimeInterval(-15 * 60),
            endTime: Date().addingTimeInterval(15 * 60),
            currentStatus: .ongoing,
            periodNumber: 3,
            progress: 0.6,
            timeRemaining: 15 * 60
        )
    }
     
    static var next: ClassActivityAttributes.ContentState {
        ClassActivityAttributes.ContentState(
            startTime: Date().addingTimeInterval(15 * 60),
            endTime: Date().addingTimeInterval(60 * 60),
            currentStatus: .upcoming,
            periodNumber: 4,
            progress: 0.0,
            timeRemaining: 15 * 60
        )
    }
}

extension Color {
    static var tint: Color {
        Color.blue
    }
}

#Preview("Notification", as: .content, using: ClassActivityAttributes.preview) {
   OutspireWidgetLiveActivity()
} contentStates: {
    ClassActivityAttributes.ContentState.current
    ClassActivityAttributes.ContentState.next
}
#endif
