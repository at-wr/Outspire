import SwiftUI
import Foundation

struct TodayView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var classtableViewModel = ClasstableViewModel()
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var isLoading = false
    @State private var animateCards = false
    @State private var hasAnimatedOnce = false // Track if we've already animated
    
    // Date formatter for the subtitle
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }
    
    var greeting: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            return "Good Morning"
        case 12..<18:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
    
    // Get upcoming class information
    var upcomingClassInfo: (period: ClassPeriod, classData: String, dayIndex: Int)? {
        guard !classtableViewModel.timetable.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentTime)
        let dayIndex = weekday == 1 ? 5 : weekday - 2 // Adjust for Swift's weekday (1 = Sunday) vs our timetable (1 = Monday)
        
        // Check for weekend (Saturday or Sunday)
        if dayIndex < 0 || dayIndex >= 5 {
            return nil // No upcoming class info on weekends
        }
        
        // Get current or upcoming period
        let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod()
        
        // If there's a current or upcoming period today
        if let period = periodInfo.period {
            // If we have data for this period in timetable
            if classtableViewModel.timetable.count > period.number &&
                1 + dayIndex < classtableViewModel.timetable[period.number].count {
                let cell = classtableViewModel.timetable[period.number][1 + dayIndex]
                let trimmedCell = cell.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !trimmedCell.isEmpty {
                    return (period, cell, dayIndex)
                }
            }
            
            // If no class in current period, look for next classes today
            let futurePeriodsToday = ClassPeriodsManager.shared.classPeriods
                .filter { $0.number > period.number }
            
            for nextPeriod in futurePeriodsToday {
                if classtableViewModel.timetable.count > nextPeriod.number &&
                    1 + dayIndex < classtableViewModel.timetable[nextPeriod.number].count {
                    let cell = classtableViewModel.timetable[nextPeriod.number][1 + dayIndex]
                    let trimmedCell = cell.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    if !trimmedCell.isEmpty {
                        return (nextPeriod, cell, dayIndex)
                    }
                }
            }
        }
        
        // If no more classes today, check for tomorrow's first class (only on weekdays, not Friday -> Saturday)
        if dayIndex < 4 { // Only check for next day if it's not Friday
            let tomorrowDayIndex = (dayIndex + 1) % 5
            if tomorrowDayIndex < 5 {
                for period in ClassPeriodsManager.shared.classPeriods {
                    if classtableViewModel.timetable.count > period.number &&
                        1 + tomorrowDayIndex < classtableViewModel.timetable[period.number].count {
                        let cell = classtableViewModel.timetable[period.number][1 + tomorrowDayIndex]
                        let trimmedCell = cell.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        if !trimmedCell.isEmpty {
                            return (period, cell, tomorrowDayIndex)
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    VStack(alignment: .leading, spacing: 5) {
                        if let nickname = sessionService.userInfo?.nickname {
                            Text("\(greeting), \(nickname)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                        } else {
                            Text("\(greeting)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.leading, 3)
                    .offset(y: animateCards ? 0 : 20)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: animateCards)
                    
                    // Main content
                    if sessionService.isAuthenticated {
                        // Upcoming class card with countdown
                        if isLoading {
                            UpcomingClassSkeletonView()
                                .padding(.horizontal)
                                .offset(y: animateCards ? 0 : 30)
                                .opacity(animateCards ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
                        } else if let upcoming = upcomingClassInfo {
                            EnhancedClassCard(
                                day: weekdayName(for: upcoming.dayIndex + 1),
                                period: upcoming.period,
                                classData: upcoming.classData,
                                currentTime: currentTime
                            )
                            .padding(.horizontal)
                            .offset(y: animateCards ? 0 : 30)
                            .opacity(animateCards ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
                        } else {
                            // Check if it's weekend and show Weekend Card, else NoClassCard
                            let calendar = Calendar.current
                            let weekday = calendar.component(.weekday, from: currentTime)
                            let dayIndex = weekday == 1 ? 5 : weekday - 2 // Adjust weekday
                            
                            if dayIndex < 0 || dayIndex >= 5 { // Weekend
                                WeekendCard()
                                    .padding(.horizontal)
                                    .offset(y: animateCards ? 0 : 30)
                                    .opacity(animateCards ? 1 : 0)
                                    .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
                            } else {
                                NoClassCard()
                                    .padding(.horizontal)
                                    .offset(y: animateCards ? 0 : 30)
                                    .opacity(animateCards ? 1 : 0)
                                    .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
                            }
                        }
                        
                        // School information cards
                        SchoolInfoCard()
                            .padding(.horizontal)
                            .offset(y: animateCards ? 0 : 40)
                            .opacity(animateCards ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateCards)
                        
                        // Schedule summary card
                        DailyScheduleCard(
                            viewModel: classtableViewModel,
                            dayIndex: Calendar.current.component(.weekday, from: currentTime) == 1 ? 4 : Calendar.current.component(.weekday, from: currentTime) - 2
                        )
                        .padding(.horizontal)
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateCards)
                    } else {
                        // Sign in prompt
                        SignInPromptCard()
                            .padding(.horizontal)
                            .offset(y: animateCards ? 0 : 30)
                            .opacity(animateCards ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
                    }
                    
                    Spacer(minLength: 60)
                }
                .padding(.top, 10)
            }
        }
        .navigationTitle("Today @ WFLA")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Get user info if authenticated but no user info is loaded
            if sessionService.isAuthenticated && sessionService.userInfo == nil {
                sessionService.fetchUserInfo { _, _ in }
            }
            
            // Fetch timetable data if authenticated
            if sessionService.isAuthenticated {
                isLoading = true
                classtableViewModel.fetchYears()
            }
            
            // Create a timer to update current time every second for countdown
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                currentTime = Date()
            }
            
            // Only trigger animations if we haven't animated before
            if !hasAnimatedOnce {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        animateCards = true
                        hasAnimatedOnce = true // Mark that we've done the animation
                    }
                }
            } else {
                // If returning from a sheet, make sure cards are visible
                animateCards = true
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: classtableViewModel.years) { _, years in
            if !years.isEmpty && !classtableViewModel.selectedYearId.isEmpty {
                classtableViewModel.fetchTimetable()
            } else if !years.isEmpty {
                classtableViewModel.selectedYearId = years.first!.W_YearID
                classtableViewModel.fetchTimetable()
            }
        }
        .onChange(of: classtableViewModel.isLoadingTimetable) { _, isLoading in
            if !isLoading {
                self.isLoading = false
            }
        }
        .onChange(of: sessionService.isAuthenticated) { _, isAuthenticated in
            // Force UI update when authentication changes
            if !isAuthenticated {
                // Clear any cached data related to the user
                classtableViewModel.timetable = []
                animateCards = false
                hasAnimatedOnce = false // Reset animation state on logout
                
                // Re-trigger animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        animateCards = true
                        hasAnimatedOnce = true
                    }
                }
            }
        }
        // Add an ID binding to force refresh when auth state changes
        .id("todayView-\(sessionService.isAuthenticated)")
    }
    
    private func weekdayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        guard index >= 1 && index <= 5 else { return "" }
        return days[index - 1]
    }
}

// Enhanced Upcoming Class Card with Countdown
struct EnhancedClassCard: View {
    let day: String
    let period: ClassPeriod
    let classData: String
    let currentTime: Date
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var isCurrentClass = false
    @State private var timer: Timer?
    
    private var components: [String] {
        classData.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
    }
    
    private var formattedCountdown: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isCurrentClass ? "Current Class" : "Upcoming Class")
                        .font(.headline)
                        .foregroundStyle(isCurrentClass ? Color.orange : Color.blue)
                    
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
                            .fill(isCurrentClass ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                    )
            }
            .padding([.horizontal, .top], 16)
            
            // Class details
            VStack(alignment: .leading, spacing: 12) {
                if components.count > 1 {
                    Text(components[1]) // Subject
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                    
                    HStack(alignment: .top, spacing: 24) {
                        // Teacher
                        Label {
                            Text(components[0])
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        
                        // Room if available
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
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(alignment: .center, spacing: 0) {
                    // Countdown info
                    HStack(spacing: 12) {
                        Image(systemName: isCurrentClass ? "timer" : "hourglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isCurrentClass ? Color.orange : Color.blue)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(isCurrentClass ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isCurrentClass ? "Class ends in" : "Class starts in")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(formattedCountdown)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(isCurrentClass ? Color.orange : Color.blue)
                                .contentTransition(.numericText())
                        }
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    // Progress indicator (shows if current class)
                    if isCurrentClass {
                        CircularProgressView(progress: calculateProgress())
                            .frame(width: 36, height: 36)
                            .padding(.trailing, 16)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            updateTimeRemaining()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        
        if now >= period.startTime && now <= period.endTime {
            isCurrentClass = true
            timeRemaining = period.endTime.timeIntervalSince(now)
        } else if period.startTime > now {
            // Class is in the future
            isCurrentClass = false
            
            // For classes more than 24 hours away (like next week's classes)
            let calendar = Calendar.current
            if calendar.dateComponents([.day], from: now, to: period.startTime).day ?? 0 > 0 {
                timeRemaining = 0
                // If class is tomorrow or later, show day of week instead of countdown
            } else {
                timeRemaining = period.startTime.timeIntervalSince(now)
            }
        } else {
            // Class is in the past, should not happen with proper data
            isCurrentClass = false
            timeRemaining = 0
        }
    }
    
    private func calculateProgress() -> Double {
        let totalDuration = period.endTime.timeIntervalSince(period.startTime)
        let elapsed = totalDuration - timeRemaining
        return min(max(elapsed / totalDuration, 0), 1)
    }
}

// Circular progress view for class progress
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
                .animation(.linear(duration: 0.2), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

// No upcoming class card
struct NoClassCard: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.1))
                )
            
            VStack(spacing: 5) {
                Text("No Classes Scheduled Today") // More specific message
                    .font(.headline)
                
                Text("Enjoy your free time!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// Weekend card
struct WeekendCard: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.yellow.opacity(0.1))
                )
            
            VStack(spacing: 5) {
                Text("It's the Weekend!")
                    .font(.headline)
                
                Text("Relax and have a great weekend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// School information card
struct SchoolInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Information", systemImage: "building.2.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 12) {
                InfoRow(icon: "bell.fill", title: "Morning Assembly", value: "7:55 - 8:05", color: .blue)
                InfoRow(icon: "fork.knife", title: "Lunch Break", value: "11:30 - 12:30", color: .orange)
                InfoRow(icon: "figure.walk", title: "After School Activities", value: "16:30 - 18:00", color: .green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// Daily schedule summary card
struct DailyScheduleCard: View {
    @ObservedObject var viewModel: ClasstableViewModel
    let dayIndex: Int
    let maxClassesToShow: Int = 3
    @State private var isExpandedSchedule = false // State for expansion
    
    private var hasClasses: Bool {
        guard !viewModel.timetable.isEmpty else { return false }
        
        // Check if we have any non-empty classes for today
        for row in 1..<viewModel.timetable.count {
            if row < viewModel.timetable.count &&
                dayIndex + 1 < viewModel.timetable[row].count &&
                !viewModel.timetable[row][dayIndex + 1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
        }
        return false
    }
    
    private var classesForToday: [(period: Int, data: String)] {
        var result: [(period: Int, data: String)] = []
        
        guard !viewModel.timetable.isEmpty else { return result }
        
        for row in 1..<viewModel.timetable.count {
            if row < viewModel.timetable.count &&
                dayIndex + 1 < viewModel.timetable[row].count {
                let classData = viewModel.timetable[row][dayIndex + 1]
                if !classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result.append((period: row, data: classData))
                }
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Today's Schedule", systemImage: "calendar.day.timeline.left")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if hasClasses {
                    Text("\(classesForToday.count) Classes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            
            Divider()
            
            if hasClasses {
                VStack(spacing: 12) {
                    ForEach(classesForToday.prefix(isExpandedSchedule ? classesForToday.count : maxClassesToShow), id: \.period) { item in // Conditional prefix based on expansion
                        let components = item.data
                            .replacingOccurrences(of: "<br>", with: "\n")
                            .components(separatedBy: "\n")
                            .filter { !$0.isEmpty }
                        
                        let period = ClassPeriodsManager.shared.classPeriods.first { $0.number == item.period }
                        
                        if let period = period, components.count > 0 {
                            ScheduleRow(
                                period: item.period,
                                time: period.timeRangeFormatted,
                                subject: components.count > 1 ? components[1] : "Class",
                                room: components.count > 2 ? components[2] : ""
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    
                    Button {
                        isExpandedSchedule.toggle() // Toggle expansion state
                    } label: {
                        HStack {
                            Text(isExpandedSchedule ? "See Less" : "See Full Schedule") // Change button text based on state
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Image(systemName: "chevron.down") // Change chevron direction, or use up/down based on state
                                .font(.caption)
                                .rotationEffect(.degrees(isExpandedSchedule ? 180 : 0)) // Rotate chevron
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color.blue)
                    }
                    .padding(.top, 6)
                }
            } else {
                Text("No classes scheduled for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// Sign in prompt card
struct SignInPromptCard: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.8))
                .padding(.bottom, 10)
            
            Text("Welcome to Outspire")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Sign in with your TSIMS account to view your personalized dashboard and class schedule")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("Go to Settings → Account → Sign In")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 10)
            
            Spacer()
        }
        .padding(.vertical, 80)
        /*
         .background(
         RoundedRectangle(cornerRadius: 16)
         .fill(Color(UIColor.systemBackground))
         .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
         )
         */
    }
}

// Information row with icon
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// Schedule row for daily schedule
struct ScheduleRow: View {
    let period: Int
    let time: String
    let subject: String
    let room: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Period circle
            Text("\(period)")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .frame(width: 26, height: 26)
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(Color.blue)
                )
            
            // Time
            Text(convertTimeFormat(time))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 105, alignment: .leading)
            
            // Subject and room
            VStack(alignment: .leading, spacing: 2) {
                Text(subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(room)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    func convertTimeFormat(_ time: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a" // Assuming input format is "h:mm a"
        
        let date24Formatter = DateFormatter()
        date24Formatter.dateFormat = "HH:mm" // Output format is "HH:mm"
        
        if let date = dateFormatter.date(from: time) {
            return date24Formatter.string(from: date)
        } else {
            return time // Return original time if conversion fails
        }
    }
}

// Skeleton view for upcoming class while loading
struct UpcomingClassSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header skeleton
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 18)
                    .frame(width: 120)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(width: 60)
            }
            .padding([.horizontal, .top], 16)
            
            // Class details skeleton
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 24)
                    .frame(width: 180)
                
                HStack(spacing: 20) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: 150)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: 100)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Countdown skeleton
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(alignment: .center, spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)
                            .frame(width: 80)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                            .frame(width: 100)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .shimmer()
    }
}



#Preview {
    NavigationView {
        TodayView()
            .environmentObject(SessionService.shared)
    }
}
