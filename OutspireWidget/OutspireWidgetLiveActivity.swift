//
//  OutspireWidgetLiveActivity.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct OutspireWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity
        var className: String
        var periodNumber: Int
        var roomNumber: String
        var timeRemaining: TimeInterval
        var isCurrentClass: Bool
        var progress: Double
    }

    // Fixed non-changing properties about your activity
    var name: String
    var teacherName: String
    var startTime: Date
    var endTime: Date
}

struct OutspireWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OutspireWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack(spacing: 12) {
                // Left side with class info
                VStack(alignment: .leading, spacing: 4) {
                    // Status and period
                    HStack {
                        Text(context.state.isCurrentClass ? "Current Class" : "Next Class")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.tint)
                        
                        Spacer()
                        
                        Text("Period \(context.state.periodNumber)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Class name
                    Text(context.state.className)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    // Room number
                    if !context.state.roomNumber.isEmpty {
                        Label {
                            Text(context.state.roomNumber)
                        } icon: {
                            Image(systemName: "mappin.circle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Right side with timer
                VStack(alignment: .trailing, spacing: 2) {
                    // Timer label
                    Text(context.state.isCurrentClass ? "Ends in" : "Starts in")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    // Timer value
                    Text(formatTimeRemaining(context.state.timeRemaining))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .monospacedDigit()
                    
                    // Progress indicator (only for current class)
                    if context.state.isCurrentClass {
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .frame(width: 60)
                            .tint(.orange)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(.secondarySystemBackground))
            .activitySystemActionForegroundColor(.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Period \(context.state.periodNumber)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(context.state.className)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.isCurrentClass ? "Ends in" : "Starts in")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(formatTimeRemaining(context.state.timeRemaining))
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .padding(.trailing, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // Room info
                        if !context.state.roomNumber.isEmpty {
                            Label {
                                Text(context.state.roomNumber)
                            } icon: {
                                Image(systemName: "mappin.circle.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Progress indicator
                        if context.state.isCurrentClass {
                            Text("\(Int(context.state.progress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                // Compact leading - Period number
                ZStack {
                    Circle()
                        .fill(Color.tint.opacity(0.2))
                        .frame(width: 20, height: 20)
                    
                    Text("\(context.state.periodNumber)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.tint)
                }
            } compactTrailing: {
                // Compact trailing - Time remaining
                Text(formatTimeRemaining(context.state.timeRemaining, compact: true))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            } minimal: {
                // Minimal - Just period number
                Text("\(context.state.periodNumber)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.tint)
            }
            .widgetURL(URL(string: "outspire://class/\(context.state.periodNumber)"))
            .keylineTint(Color.tint)
        }
    }
    
    // Helper function to format time remaining
    private func formatTimeRemaining(_ timeInterval: TimeInterval, compact: Bool = false) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        if let formatted = formatter.string(from: timeInterval) {
            // If it has hours, keep the full format
            if formatted.contains(":") && formatted.split(separator: ":").count == 3 {
                return compact ? String(formatted.prefix(5)) : formatted
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
}

extension OutspireWidgetAttributes {
    fileprivate static var preview: OutspireWidgetAttributes {
        let now = Date()
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 10, minute: 45, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 11, minute: 25, second: 0, of: now)!
        
        return OutspireWidgetAttributes(
            name: "Class Activity",
            teacherName: "Mr. Smith",
            startTime: startTime,
            endTime: endTime
        )
    }
}

extension OutspireWidgetAttributes.ContentState {
    fileprivate static var current: OutspireWidgetAttributes.ContentState {
        OutspireWidgetAttributes.ContentState(
            className: "Mathematics",
            periodNumber: 4,
            roomNumber: "A101",
            timeRemaining: 15 * 60, // 15 minutes
            isCurrentClass: true,
            progress: 0.6
        )
    }
     
    fileprivate static var next: OutspireWidgetAttributes.ContentState {
        OutspireWidgetAttributes.ContentState(
            className: "Science",
            periodNumber: 5,
            roomNumber: "B202",
            timeRemaining: 30 * 60, // 30 minutes
            isCurrentClass: false,
            progress: 0.0
        )
    }
}

extension Color {
    static var tint: Color {
        Color.blue
    }
}

#Preview("Notification", as: .content, using: OutspireWidgetAttributes.preview) {
   OutspireWidgetLiveActivity()
} contentStates: {
    OutspireWidgetAttributes.ContentState.current
    OutspireWidgetAttributes.ContentState.next
}
