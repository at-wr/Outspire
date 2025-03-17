//
//  OutspireWidgetLiveActivity.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Make sure we're using a single consistent attributes structure
struct ClassActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic content that can change during updates
        var startTime: Date
        var endTime: Date
        var currentStatus: ClassStatus
        var periodNumber: Int
        var progress: Double // Add progress for UI visualization
        var timeRemaining: TimeInterval // Add time remaining for simpler display
    }
    
    // Static content that doesn't change during the activity lifecycle
    var className: String
    var roomNumber: String
    var teacherName: String
    
    enum ClassStatus: String, Codable {
        case upcoming
        case ongoing
        case ending   // last 5 minutes
    }
    
    // Preview helper
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
                        if !context.attributes.roomNumber.isEmpty {
                            Label {
                                Text(context.attributes.roomNumber)
                            } icon: {
                                Image(systemName: "mappin.circle.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Teacher info
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
                        
                        // Progress indicator
                        if context.state.currentStatus != .upcoming {
                            VStack(spacing: 2) {
                                ProgressView(value: context.state.progress)
                                    .progressViewStyle(.linear)
                                    .frame(width: 60)
                                    .tint(.orange)
                                
                                Text("\(Int(context.state.progress * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
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
            .widgetURL(URL(string: "outspire://today"))
            .keylineTint(statusColor(for: context.state.currentStatus))
        }
    }
    
    // Helper to format time for display
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
    
    // Helper for status-based color
    private func statusColor(for status: ClassActivityAttributes.ClassStatus) -> Color {
        switch status {
        case .upcoming: return .blue
        case .ongoing: return .green
        case .ending: return .orange
        }
    }
}

// Lock screen view
struct LockScreenView: View {
    let context: ActivityViewContext<ClassActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side with class info
            VStack(alignment: .leading, spacing: 4) {
                // Status and period
                HStack {
                    Text(context.state.currentStatus == .upcoming ? "Next Class" : "Current Class")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.tint)
                    
                    Spacer()
                    
                    Text("Period \(context.state.periodNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Class name
                Text(context.attributes.className)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                // Room number
                if !context.attributes.roomNumber.isEmpty {
                    Label {
                        Text(context.attributes.roomNumber)
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
                Text(context.state.currentStatus == .upcoming ? "Starts in" : "Ends in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                // Timer value
                Text(formatTimeRemaining(context.state.timeRemaining))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .monospacedDigit()
                
                // Progress indicator (only for current class)
                if context.state.currentStatus != .upcoming {
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
    }
    
    // Helper to format time for display
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
}

// MARK: - Preview Helpers
extension ClassActivityAttributes.ContentState {
    static var current: ClassActivityAttributes.ContentState {
        ClassActivityAttributes.ContentState(
            startTime: Date().addingTimeInterval(-15 * 60), // 15 min ago
            endTime: Date().addingTimeInterval(15 * 60),    // 15 min from now
            currentStatus: .ongoing,
            periodNumber: 3,
            progress: 0.6,
            timeRemaining: 15 * 60 // 15 minutes
        )
    }
     
    static var next: ClassActivityAttributes.ContentState {
        ClassActivityAttributes.ContentState(
            startTime: Date().addingTimeInterval(15 * 60),  // 15 min from now
            endTime: Date().addingTimeInterval(60 * 60),    // 1 hour from now
            currentStatus: .upcoming,
            periodNumber: 4,
            progress: 0.0,
            timeRemaining: 15 * 60 // 15 minutes
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
