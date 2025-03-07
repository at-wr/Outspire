import WidgetKit
import SwiftUI
import ActivityKit
import ClassActivityModule

struct ClassActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClassActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.subject)
                            .font(.headline)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: context.state.isCurrentClass ? "timer" : "hourglass")
                            .foregroundStyle(context.state.isCurrentClass ? .orange : .blue)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(timeRemainingFormatted(startTime: context.state.startTime, endTime: context.state.endTime, isCurrentClass: context.state.isCurrentClass))
                    } icon: {
                        Image(systemName: "clock")
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                            Text(context.state.teacher)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.secondary)
                            Text(context.state.room)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if context.state.isCurrentClass {
                            ProgressView(value: calculateProgress(startTime: context.state.startTime, endTime: context.state.endTime))
                                .progressViewStyle(.linear)
                                .tint(.orange)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Label {
                    Text("P\(context.state.periodNumber)")
                } icon: {
                    Image(systemName: context.state.isCurrentClass ? "timer" : "hourglass")
                        .foregroundStyle(context.state.isCurrentClass ? .orange : .blue)
                }
            } compactTrailing: {
                Text(timeRemainingFormatted(startTime: context.state.startTime, endTime: context.state.endTime, isCurrentClass: context.state.isCurrentClass, compact: true))
            } minimal: {
                Image(systemName: context.state.isCurrentClass ? "timer" : "hourglass")
                    .foregroundStyle(context.state.isCurrentClass ? .orange : .blue)
            }
        }
    }
    
    private func calculateProgress(startTime: Date, endTime: Date) -> Double {
        let now = Date()
        if now < startTime { return 0 }
        if now > endTime { return 1 }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsedDuration = now.timeIntervalSince(startTime)
        return elapsedDuration / totalDuration
    }
    
    private func timeRemainingFormatted(startTime: Date, endTime: Date, isCurrentClass: Bool, compact: Bool = false) -> String {
        let now = Date()
        let timeRemaining: TimeInterval
        
        if isCurrentClass {
            timeRemaining = endTime.timeIntervalSince(now)
        } else {
            timeRemaining = startTime.timeIntervalSince(now)
        }
        
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if compact {
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<ClassActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.isCurrentClass ? "Current Class" : "Upcoming Class")
                        .font(.headline)
                        .foregroundStyle(context.state.isCurrentClass ? Color.orange : Color.blue)
                    
                    Text("\(context.attributes.classDay) • Period \(context.state.periodNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Show remaining time
                VStack(alignment: .trailing) {
                    Text(timeRemainingFormatted(startTime: context.state.startTime, endTime: context.state.endTime, isCurrentClass: context.state.isCurrentClass))
                        .font(.system(.title2, design: .rounded))
                        .foregroundStyle(context.state.isCurrentClass ? Color.orange : Color.blue)
                    
                    Text(context.state.isCurrentClass ? "until end" : "until start")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.subject)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 16) {
                        Label {
                            Text(context.state.teacher)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        
                        Label {
                            Text(context.state.room)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if context.state.isCurrentClass {
                    // Show progress indicator for current class
                    CircularProgressView(progress: calculateProgress(startTime: context.state.startTime, endTime: context.state.endTime))
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding()
    }
    
    private func calculateProgress(startTime: Date, endTime: Date) -> Double {
        let now = Date()
        if now < startTime { return 0 }
        if now > endTime { return 1 }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsedDuration = now.timeIntervalSince(startTime)
        return elapsedDuration / totalDuration
    }
    
    private func timeRemainingFormatted(startTime: Date, endTime: Date, isCurrentClass: Bool) -> String {
        let now = Date()
        let timeRemaining: TimeInterval
        
        if isCurrentClass {
            timeRemaining = endTime.timeIntervalSince(now)
        } else {
            timeRemaining = startTime.timeIntervalSince(now)
        }
        
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}