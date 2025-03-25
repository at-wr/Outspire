import SwiftUI

struct EnhancedClassCard: View {
    let day: String
    let period: ClassPeriod
    let classData: String
    let currentTime: Date
    let isForToday: Bool
    let setAsToday: Bool
    let effectiveDate: Date?
    var hasActiveActivity: Bool = false
    var toggleLiveActivity: (() -> Void)?
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var isCurrentClass = false
    @State private var timer: Timer?
    @State private var isTransitioning = false
    @State private var isTimeComplete = false // New state to track if time is actually complete
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var components: [String] {
        classData.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
    }
    
    // Check if this is a self-study period
    private var isSelfStudy: Bool {
        return classData.contains("Self-Study")
    }
    
    // Dynamic color based on class type and status
    private var statusColor: Color {
        if isSelfStudy {
            return .purple
        } else if isCurrentClass {
            return .orange
        } else {
            // Use subject-specific color if we can determine it
            if components.count > 1 {
                return ClasstableView.getSubjectColor(from: components[1])
            }
            return .blue
        }
    }
    
    private var formattedCountdown: String {
        if isTimeComplete {
            return "00:00" // Only show zeros when we've confirmed time is complete
        }
        
        // Always show positive time remaining
        let remainingSeconds = max(0, timeRemaining)
        
        let hours = Int(remainingSeconds) / 3600
        let minutes = (Int(remainingSeconds) % 3600) / 60
        let seconds = Int(remainingSeconds) % 60
        
        // Only show hours when needed to avoid redundant "0:MM:SS" format
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with class info
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    if isForToday {
                        Text(isCurrentClass ? "Current Class" : "Upcoming Class")
                            .font(.headline)
                            .foregroundStyle(statusColor)
                    } else {
                        Text("Scheduled Class")
                            .font(.headline)
                            .foregroundStyle(statusColor)
                    }
                    
                    Text("\(day) • Period \(period.number)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(period.timeRangeFormatted)
                    .font(.subheadline)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(statusColor.opacity(0.1))
                    )
            }
            .padding([.horizontal, .top], 16)
            
            // Class details
            VStack(alignment: .leading, spacing: 12) {
                if components.count > 1 {
                    Text(components[1])
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                    
                    HStack(alignment: .top, spacing: 24) {
                        Label {
                            Text(components[0])
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        
                        if components.count > 2 {
                            Label {
                                Text(components[2])
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Countdown section
            if isForToday || setAsToday || Configuration.showCountdownForFutureClasses {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    HStack(alignment: .center, spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: isCurrentClass ? "timer" : "hourglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(statusColor)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(statusColor.opacity(0.1))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isCurrentClass ? "Class ends in" : "Class starts in")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(formattedCountdown)
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(statusColor)
                                    .monospacedDigit()
                                    .fixedSize(horizontal: true, vertical: false) // Prevent horizontal resizing
                                    .frame(minWidth: 80, alignment: .leading) // Ensures consistent minimum width
                                    .contentTransition(.numericText())
                                    .transaction { t in
                                        t.animation = .default
                                    }
                            }
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        if isCurrentClass && (isForToday || setAsToday) {
                            EnhancedCircularProgressView(progress: calculateProgress())
                                .frame(width: 36, height: 36)
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.vertical, 10)
#if !targetEnvironment(macCatalyst)
                    // Live Activity toggle button
                    if (isForToday || setAsToday) && toggleLiveActivity != nil {
                        Divider()
                            .padding(.horizontal, 16)
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            toggleLiveActivity?()
                        }) {
                            HStack {
                                Image(systemName: hasActiveActivity ? "pause.circle" : "play.circle")
                                    .font(.caption)
                                Text(hasActiveActivity ? "Stop Live Activity" : "Start Live Activity")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 3)
                            .foregroundStyle(statusColor)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                    }
                    #endif
                }
            }
        }
        .background(
            ZStack {
                // Base blur layer
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(colorScheme == .dark ? 0.8 : 0.92)
                
                // Subtle gradient overlay for depth
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.3),
                                Color.white.opacity(colorScheme == .dark ? 0.02 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Very subtle border - synced with GlassmorphicCard
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.5),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.08),
                radius: 15,
                x: 0,
                y: 5
            )
        )
        .onAppear {
            isTimeComplete = false
            isTransitioning = false
            calculateTimeRemaining()
            // Use a timer that updates every second but prevents UI jitter
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
                self.calculateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: setAsToday) {
            calculateTimeRemaining()
        }
        .onChange(of: day) {
            calculateTimeRemaining()
        }
        .onChange(of: effectiveDate) {
            calculateTimeRemaining()
        }
    }
    
    // Make this function not update state if we're already at zero
    private func calculateTimeRemaining() {
        // Don't recalculate if we've determined time is complete and UI shows correct state
        if isTimeComplete && !isCurrentClass {
            return
        }
        
        let calendar = Calendar.current
        let now = Date() // Current real time
        
        if setAsToday && effectiveDate != nil {
            // For "Set as Today" mode with an effectiveDate
            let effectiveTime = getTimeComponents(from: now)
            let effectiveDay = getDateComponents(from: effectiveDate!)
            
            // Combine the current time with the effective date
            var effectiveNowComponents = DateComponents()
            effectiveNowComponents.year = effectiveDay.year
            effectiveNowComponents.month = effectiveDay.month
            effectiveNowComponents.day = effectiveDay.day
            effectiveNowComponents.hour = effectiveTime.hour
            effectiveNowComponents.minute = effectiveTime.minute
            effectiveNowComponents.second = effectiveTime.second
            
            guard let effectiveNow = calendar.date(from: effectiveNowComponents) else { return }
            
            // Create adjusted period times based on the effective date
            let adjustedStartTime = createAdjustedTime(from: period.startTime, onDate: effectiveDate!)
            let adjustedEndTime = createAdjustedTime(from: period.endTime, onDate: effectiveDate!)
            
            if effectiveNow >= adjustedStartTime && effectiveNow <= adjustedEndTime {
                isCurrentClass = true
                let newTimeRemaining = adjustedEndTime.timeIntervalSince(effectiveNow)
                
                // Only update time if it has meaningfully changed (more than 0.5s difference)
                // This prevents unnecessary UI refreshes
                if abs(newTimeRemaining - timeRemaining) > 0.5 {
                    timeRemaining = newTimeRemaining
                }
                
                // Critical fix: When time remaining is <= 0, find next period
                // But do this check without changing state unnecessarily
                if timeRemaining <= 1 {
                    if let nextPeriod = findNextPeriodToday(after: period, on: effectiveDate!) {
                        let nextStartTime = createAdjustedTime(from: nextPeriod.startTime, onDate: effectiveDate!)
                        // Use isTransitioning state to prevent flickering during transition
                        if !isTransitioning {
                            isTransitioning = true
                            
                            // Slight delay before transitioning to next period
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isCurrentClass = false
                                    timeRemaining = nextStartTime.timeIntervalSince(effectiveNow)
                                    isTimeComplete = false
                                    isTransitioning = false
                                }
                            }
                        }
                    } else {
                        isTimeComplete = true
                        timeRemaining = 0
                    }
                }
            } else if effectiveNow < adjustedStartTime {
                isCurrentClass = false
                let newTimeRemaining = adjustedStartTime.timeIntervalSince(effectiveNow)
                
                // Only update time if it has meaningfully changed
                if abs(newTimeRemaining - timeRemaining) > 0.5 {
                    timeRemaining = newTimeRemaining
                }
                isTimeComplete = false
            } else {
                isCurrentClass = false
                // Check if there's a next period today
                if let nextPeriod = findNextPeriodToday(after: period, on: effectiveDate!) {
                    let nextStartTime = createAdjustedTime(from: nextPeriod.startTime, onDate: effectiveDate!)
                    timeRemaining = nextStartTime.timeIntervalSince(effectiveNow)
                } else {
                    // If no next period, show "0" but with indication it's done
                    timeRemaining = 0
                }
            }
        } else if isForToday {
            // Regular today logic - FIX the countdown bug
            if now >= period.startTime && now <= period.endTime {
                // Current class
                isCurrentClass = true
                let newTimeRemaining = period.endTime.timeIntervalSince(now)
                
                // Only update time if it has meaningfully changed
                if abs(newTimeRemaining - timeRemaining) > 0.5 {
                    timeRemaining = newTimeRemaining
                }
                isTimeComplete = false
                
                // Fix for countdown reaching zero - check if we need to transition
                if timeRemaining <= 1 {
                    // Find the next class period
                    if let nextPeriod = findNextPeriodToday(after: period, on: now) {
                        // Use isTransitioning state to prevent flickering during transition
                        if !isTransitioning {
                            isTransitioning = true
                            
                            // Slight delay before transitioning to next period
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isCurrentClass = false
                                    timeRemaining = nextPeriod.startTime.timeIntervalSince(now)
                                    isTimeComplete = false
                                    isTransitioning = false
                                }
                            }
                        }
                    } else {
                        isTimeComplete = true
                        timeRemaining = 0
                    }
                }
            } else if now < period.startTime {
                // Upcoming class
                isCurrentClass = false
                let newTimeRemaining = period.startTime.timeIntervalSince(now)
                
                // Only update time if it has meaningfully changed
                if abs(newTimeRemaining - timeRemaining) > 0.5 {
                    timeRemaining = newTimeRemaining
                }
                isTimeComplete = false
            } else {
                // Class has ended - check for next period more robustly
                isCurrentClass = false
                if let nextPeriod = findNextPeriodToday(after: period, on: now) {
                    let newTimeRemaining = nextPeriod.startTime.timeIntervalSince(now)
                    
                    // Only update time if it has meaningfully changed
                    if abs(newTimeRemaining - timeRemaining) > 0.5 {
                        timeRemaining = newTimeRemaining
                    }
                    isTimeComplete = false
                } else {
                    // End of day, no more classes
                    isTimeComplete = true
                    timeRemaining = 0
                }
            }
        } else {
            // Logic for future days (preview mode)
            guard let dayOfWeek = weekdayFromDayName(day) else { return }
            let currentWeekday = calendar.component(.weekday, from: now)
            var daysToAdd = dayOfWeek - currentWeekday
            if daysToAdd <= 0 {
                daysToAdd += 7
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: now)) else { return }
            var components = calendar.dateComponents([.year, .month, .day], from: nextDate)
            let periodStartComponents = calendar.dateComponents([.hour, .minute], from: period.startTime)
            components.hour = periodStartComponents.hour
            components.minute = periodStartComponents.minute
            components.second = 0
            
            guard let futureStartTime = calendar.date(from: components) else { return }
            isCurrentClass = false
            let newTimeRemaining = futureStartTime.timeIntervalSince(now)
            if abs(newTimeRemaining - timeRemaining) > 0.5 {
                timeRemaining = newTimeRemaining
            }
            isTimeComplete = false
        }
    }
    
    // Helper method to create a time on a specific date
    private func createAdjustedTime(from time: Date, onDate date: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second
        
        return calendar.date(from: dateComponents) ?? date
    }
    
    private func calculateProgress() -> Double {
        let totalDuration = period.endTime.timeIntervalSince(period.startTime)
        let elapsed = totalDuration - timeRemaining
        return max(0, min(1, elapsed / totalDuration))
    }
    
    private func weekdayFromDayName(_ name: String) -> Int? {
        let dayMapping = ["Mon": 2, "Tue": 3, "Wed": 4, "Thu": 5, "Fri": 6]
        return dayMapping[name]
    }
    
    // Helper method to get time components
    private func getTimeComponents(from date: Date) -> DateComponents {
        return Calendar.current.dateComponents([.hour, .minute, .second], from: date)
    }
    
    // Helper method to get date components (year, month, day)
    private func getDateComponents(from date: Date) -> DateComponents {
        return Calendar.current.dateComponents([.year, .month, .day], from: date)
    }
    
    // Add this helper method to find the next period:
    private func findNextPeriodToday(after currentPeriod: ClassPeriod, on date: Date) -> ClassPeriod? {
        return ClassPeriodsManager.shared.classPeriods
            .filter { $0.number > currentPeriod.number }
            .sorted { $0.number < $1.number }
            .first
    }
}

// Circular progress view component
private struct EnhancedCircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: 4
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    Color.orange,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90)) // Start from the top
                .animation(.linear(duration: 0.1), value: progress)
            
            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
        }
    }
}
