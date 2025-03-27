import SwiftUI
import ColorfulX

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
    @State private var isNextClass = false // New state to track if this is the next class
    @State private var circlePercent: Double = 0.0  // Add the missing circlePercent property
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var gradientManager: GradientManager
    
    var showCountdown: Bool = true
    
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
    
    // Improved version of statusTextColor with better contrast
    private var statusTextColor: Color {
        if colorScheme == .dark {
            // For dark mode, use a more subtle but still readable color
            return Color.white.opacity(0.9)
        } else {
            // For light mode, use the theme color with slight adjustment
            return statusColor.adjustBrightness(by: -0.1)
        }
    }
    
    // Better background color for status items in dark mode
    private var statusBackgroundColor: Color {
        if colorScheme == .dark {
            // Subtle dark background that doesn't compete with text
            return Color.black.opacity(0.3)
        } else {
            return statusColor.opacity(0.15)
        }
    }
    
    // Add a stronger outline color for text
    private var textOutlineColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.5) : Color.white.opacity(0.5)
    }
    
    // Define a new color for secondary text that has better contrast
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.65)
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
                            .fontWeight(.semibold)
                            .foregroundStyle(statusTextColor)
                    } else {
                        Text("Scheduled Class")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(statusTextColor)
                    }
                    
                    Text("\(day) • Period \(period.number)")
                        .font(.subheadline)
                        .foregroundStyle(secondaryTextColor)
                }
                
                Spacer()
                
                Text(period.timeRangeFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(statusBackgroundColor)
                    )
                    .foregroundStyle(statusTextColor)
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
                                .foregroundStyle(secondaryTextColor)
                        }
                        .font(.subheadline)
                        
                        if components.count > 2 {
                            Label {
                                Text(components[2])
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(secondaryTextColor)
                            }
                            .font(.subheadline)
                        }
                    }
                    .foregroundStyle(secondaryTextColor)
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
                            // Timer icon with improved visibility
                            ZStack {
                                Circle()
                                    .fill(statusBackgroundColor)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: isCurrentClass ? "timer" : "hourglass")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(statusTextColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isCurrentClass ? "Class ends in" : "Class starts in")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(secondaryTextColor)
                                
                                Text(formattedCountdown)
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(statusTextColor)
                                    .monospacedDigit()
                                    .fixedSize(horizontal: true, vertical: false)
                                    .frame(minWidth: 80, alignment: .leading)
                                    .contentTransition(.numericText())
                                    .transaction { t in
                                        t.animation = .default
                                    }
                            }
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        if isCurrentClass && (isForToday || setAsToday) {
                            EnhancedCircularProgressView(progress: circlePercent)
                                .frame(width: 36, height: 36)
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.vertical, 10)
#if !targetEnvironment(macCatalyst)
                    // Live Activity toggle button with better contrast
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
                                    .imageScale(.medium)
                                
                                Text(hasActiveActivity ? "Stop Live Activity" : "Start Live Activity")
                                    .font(.callout)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .foregroundStyle(colorScheme == .dark ? .white : statusTextColor)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? 
                                          Color.black.opacity(0.3) : 
                                          statusBackgroundColor.opacity(0.7))
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                    }
                    #endif
                }
            }
        }
        .glassmorphicCard() // Replace custom background implementation with shared component
        .onAppear {
            setupTimer()
            updateClassStatus()
    checkAndUpdateGradient()
    updateCirclePercent()
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
                        if (!isTransitioning) {
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
                        if (!isTransitioning) {
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
        
        // Check and update gradient if needed
        checkAndUpdateGradient()
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
    
    // Helper function to update the gradient when this card is displayed
    private func updateGradientForCard() {
        // Only update if this is the active upcoming class
        if isCurrentClass || isNextClass {
            let context: GradientContext
            
            if isCurrentClass {
                context = isSelfStudy ? .inSelfStudy : .inClass(subject: classData)
            } else {
                context = isSelfStudy ? .upcomingSelfStudy : .upcomingClass(subject: classData)
            }
            
            gradientManager.updateGradientForContext(
                context: context,
                colorScheme: colorScheme
            )
        }
    }
    
    // Add a function to check if we need to update the gradient
    private func checkAndUpdateGradient() {
        if isCurrentClass || (showCountdown && timeRemaining > 0 && timeRemaining < 3600) {
            // Consider this card as the "next class" if we're showing a countdown
            // and the time remaining is less than an hour
            isNextClass = !isCurrentClass && showCountdown && timeRemaining > 0 && timeRemaining < 3600
            updateGradientForCard()
        }
    }
    
    // MARK: - Private Methods
    
    // Sets up the timer for countdown updates
    private func setupTimer() {
        // Cancel any existing timer first
        timer?.invalidate()
        
        // Create a new timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Remove 'weak self' since EnhancedClassCard is a struct
            self.updateTimeRemaining()
        }
        
        // Make sure timer runs even during scrolling
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        // Initial update
        updateTimeRemaining()
    }
    
    // Updates the class status
    private func updateClassStatus() {
        // Get current date and class times
        let now = Date()
        let effectiveDate = getEffectiveDate()
        
        if let effectiveDate = effectiveDate {
            let calendar = Calendar.current
            
            // Create components for effective now
            var effectiveNowComponents = calendar.dateComponents([.year, .month, .day], from: effectiveDate)
            let nowTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
            effectiveNowComponents.hour = nowTimeComponents.hour
            effectiveNowComponents.minute = nowTimeComponents.minute
            effectiveNowComponents.second = nowTimeComponents.second
            
            guard let effectiveNow = calendar.date(from: effectiveNowComponents) else { return }
            
            // Create adjusted period times
            let adjustedStartTime = createAdjustedTime(from: period.startTime, onDate: effectiveDate)
            let adjustedEndTime = createAdjustedTime(from: period.endTime, onDate: effectiveDate)
            
            // Set current class status
            isCurrentClass = effectiveNow >= adjustedStartTime && effectiveNow <= adjustedEndTime
            
            // Set next class status if not current class
            if !isCurrentClass {
                isNextClass = effectiveNow < adjustedStartTime && 
                              adjustedStartTime.timeIntervalSince(effectiveNow) < 3600 // Within the next hour
            } else {
                isNextClass = false
            }
            
            // Update time remaining based on status
            if isCurrentClass {
                timeRemaining = adjustedEndTime.timeIntervalSince(effectiveNow)
            } else if effectiveNow < adjustedStartTime {
                timeRemaining = adjustedStartTime.timeIntervalSince(effectiveNow)
            } else {
                timeRemaining = 0
                isTimeComplete = true
            }
            
            // Update circle percent
            updateCirclePercent()
        }
    }
    
    // Get the effective date for calculations
    private func getEffectiveDate() -> Date? {
        if setAsToday && effectiveDate != nil {
            return effectiveDate
        } else {
            return Date()
        }
    }
    
    // Updates the time remaining for the countdown
    private func updateTimeRemaining() {
        // Calculate the time remaining
        calculateTimeRemaining()
    }
    
    // Updates the circle percent for the progress view
    private func updateCirclePercent() {
        // Calculate the current progress
        let progress = calculateProgress()
        
        // Update the circle percent based on progress
        withAnimation(.linear(duration: 0.5)) {
            circlePercent = progress
        }
    }
}

// Circular progress view component
private struct EnhancedCircularProgressView: View {
    let progress: Double
    @Environment(\.colorScheme) private var colorScheme
    
    // Better progress color for dark mode
    private var progressColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.8) : Color.orange
    }
    
    // Better background color for the progress ring
    private var progressBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.25)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    progressBackgroundColor,
                    lineWidth: 4
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            // Percentage text with better contrast
            Text("\(Int(progress * 100))%")
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .secondary)
        }
    }
}
