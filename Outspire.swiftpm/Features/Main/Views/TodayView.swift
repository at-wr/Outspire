import SwiftUI

struct TodayView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var classtableViewModel = ClasstableViewModel()
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var isLoading = false
    
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
        
        // Adjust for Swift's weekday (1 = Sunday) vs our timetable (1 = Monday)
        let dayIndex = weekday == 1 ? 5 : weekday - 2
        
        // Guard against weekend
        if dayIndex < 0 || dayIndex >= 5 { return nil }
        
        // Get current or upcoming period
        let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod()
        
        // If there's a current or upcoming period today
        if let period = periodInfo.period {
            // If we have data for this period in timetable
            if classtableViewModel.timetable.count > period.number &&
               1 + dayIndex < classtableViewModel.timetable[period.number].count {
                let cell = classtableViewModel.timetable[period.number][1 + dayIndex]
                if !cell.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                    if !cell.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return (nextPeriod, cell, dayIndex)
                    }
                }
            }
        }
        
        // If no more classes today, check for tomorrow's first class
        let tomorrowDayIndex = (dayIndex + 1) % 5
        if tomorrowDayIndex < 5 {
            for period in ClassPeriodsManager.shared.classPeriods {
                if classtableViewModel.timetable.count > period.number &&
                   1 + tomorrowDayIndex < classtableViewModel.timetable[period.number].count {
                    let cell = classtableViewModel.timetable[period.number][1 + tomorrowDayIndex]
                    if !cell.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return (period, cell, tomorrowDayIndex)
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
            
            VStack(spacing: 25) {
                if let nickname = sessionService.userInfo?.nickname {
                    VStack {
                        Text("\(greeting), \(nickname)")
                            .font(.title2)
                    }
                    .navigationTitle("\(greeting)")
                } else {
                    VStack {
                        Text("Welcome to Outspire")
                            .foregroundStyle(.primary)
                            .font(.title2)
                        Text("Sign in with WFLA TSIMS account to continue")
                            .foregroundStyle(.secondary)
                        Text("(Settings Icon > Account > Sign In)")
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // Upcoming class card
                if sessionService.isAuthenticated {
                    if isLoading {
                        UpcomingClassSkeletonView()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                    } else if let upcoming = upcomingClassInfo {
                        UpcomingClassCard(
                            day: weekdayName(for: upcoming.dayIndex + 1),
                            period: upcoming.period,
                            classInfo: upcoming.classData
                        )
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
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
            
            // Create a timer to update current time every minute
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
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
    }
    
    private func weekdayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        guard index >= 1 && index <= 5 else { return "" }
        return days[index-1]
    }
}

// Upcoming Class Card View
struct UpcomingClassCard: View {
    let day: String
    let period: ClassPeriod
    let classInfo: String
    
    private var components: [String] {
        classInfo.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Class")
                    .font(.headline)
                
                Spacer()
                
                Text(day)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: 4) {
                    Text("\(period.number)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Text(period.timeRangeFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 80)
                
                Divider()
                    .padding(.horizontal, 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    if components.count > 1 {
                        Text(components[1])
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("Teacher: \(components[0])")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if components.count > 2 {
                            Text("Room: \(components[2])")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
}

// Skeleton view for upcoming class while loading
struct UpcomingClassSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 18)
                    .frame(width: 120)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(width: 40)
            }
            
            Divider()
            
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .frame(width: 60)
                }
                .frame(width: 80)
                
                Divider()
                    .padding(.horizontal, 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .frame(width: 160)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 14)
                        .frame(width: 120)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 14)
                        .frame(width: 100)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .shimmer()
    }
}
