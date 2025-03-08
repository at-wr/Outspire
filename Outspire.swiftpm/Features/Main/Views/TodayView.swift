import SwiftUI
import Foundation

struct TodayView: View {
    // MARK: - Environment & State
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var classtableViewModel = ClasstableViewModel()
    
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var isLoading = false
    @State private var animateCards = false
    @State private var hasAnimatedOnce = false
    @State private var selectedDayOverride: Int? = nil
    @State private var isHolidayMode: Bool = false
    @State private var isSettingsSheetPresented: Bool = false
    @State private var holidayEndDate: Date = Date().addingTimeInterval(86400)
    @State private var holidayHasEndDate: Bool = false
    @State private var setAsToday: Bool = false
    
    // MARK: - Computed Properties
    private var formattedDate: String {
        TodayViewHelpers.formatDateString(currentTime)
    }
    
    var greeting: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Good Morning"
        case 12..<18: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var effectiveDayIndex: Int {
        if isHolidayActive() {
            return -1
        }
        if let override = selectedDayOverride {
            return override
        } else {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: currentTime)
            return (weekday == 1 || weekday == 7) ? -1 : weekday - 2
        }
    }
    
    private var assemblyTime: String {
        let dayIndex = effectiveDayIndex
        if dayIndex == 0 { return "7:45 - 8:05" }           // Monday
        else if dayIndex >= 1 && dayIndex <= 4 { return "7:55 - 8:05" } // Tues - Fri
        else { return "No assembly" }
    }
    
    private var arrivalTime: String {
        let dayIndex = effectiveDayIndex
        if dayIndex == 0 { return "before 7:45" }           // Monday
        else if dayIndex >= 1 && dayIndex <= 4 { return "before 7:55" } // Tues - Fri
        else { return "No arrival requirement" }
    }
    
    var upcomingClassInfo: (period: ClassPeriod, classData: String, dayIndex: Int, isForToday: Bool)? {
        guard !classtableViewModel.timetable.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let isForToday = selectedDayOverride == nil
        let isWeekendToday = (currentWeekday == 1 || currentWeekday == 7)
        let dayIndex = effectiveDayIndex
        
        if isHolidayActive() { return nil }
        if isForToday && isWeekendToday && Configuration.showMondayClass {
            return getNextClassForDay(0, isForToday: false)
        }
        if dayIndex < 0 || dayIndex >= 5 { return nil }
        return getNextClassForDay(dayIndex, isForToday: isForToday)
    }
    
    private var holidayEndDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: holidayEndDate)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    mainContentView
                    Spacer(minLength: 60)
                }
                .padding(.top, 10)
            }
        }
        .navigationTitle("Today @ WFLA")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isSettingsSheetPresented = true
                } label: {
                    Image(systemName: "calendar.badge.clock")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(selectedDayOverride != nil || isHolidayMode ? .blue : .primary)
                }
            }
        }
        .sheet(isPresented: $isSettingsSheetPresented) {
            ScheduleSettingsSheet(
                selectedDay: $selectedDayOverride,
                setAsToday: $setAsToday,
                isHolidayMode: $isHolidayMode,
                isPresented: $isSettingsSheetPresented,
                holidayEndDate: $holidayEndDate,
                holidayHasEndDate: $holidayHasEndDate
            )
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            setupOnAppear()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: classtableViewModel.years) { _, years in
            handleYearsChange(years)
        }
        .onChange(of: classtableViewModel.isLoadingTimetable) { _, isLoading in
            self.isLoading = isLoading
        }
        .onChange(of: sessionService.isAuthenticated) { _, isAuthenticated in
            handleAuthChange(isAuthenticated)
        }
        .id("todayView-\(sessionService.isAuthenticated)")
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var headerView: some View {
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
            additionalHeaderText
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.leading, 3)
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: animateCards)
    }
    
    @ViewBuilder
    private var additionalHeaderText: some View {
        if let override = selectedDayOverride {
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundStyle(.blue)
                Text("Viewing \(TodayViewHelpers.weekdayName(for: override + 1))'s schedule")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        } else if isHolidayActive() && holidayHasEndDate {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("Holiday Mode Until \(holidayEndDateString)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } else if isHolidayMode {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("Holiday Mode Enabled")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func animatedCard<Content: View>(delay: Double, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal)
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(delay), value: animateCards)
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if sessionService.isAuthenticated {
            if isHolidayActive() {
                animatedCard(delay: 0.1) {
                    HolidayModeCard(hasEndDate: holidayHasEndDate, endDate: holidayEndDate)
                }
            } else if isLoading {
                animatedCard(delay: 0.1) {
                    UpcomingClassSkeletonView()
                }
            } else if let upcoming = upcomingClassInfo {
                animatedCard(delay: 0.1) {
                    EnhancedClassCard(
                        day: TodayViewHelpers.weekdayName(for: upcoming.dayIndex + 1),
                        period: upcoming.period,
                        classData: upcoming.classData,
                        currentTime: currentTime,
                        isForToday: upcoming.isForToday,
                        setAsToday: setAsToday && selectedDayOverride != nil
                    )
                }
            } else {
                let isWeekend = isCurrentDateWeekend()
                if isWeekend {
                    animatedCard(delay: 0.1) {
                        WeekendCard()
                    }
                } else {
                    animatedCard(delay: 0.1) {
                        NoClassCard()
                    }
                }
            }
            
            animatedCard(delay: 0.2) {
                SchoolInfoCard(assemblyTime: assemblyTime, arrivalTime: arrivalTime)
            }
            
            if !isHolidayMode {
                animatedCard(delay: 0.3) {
                    DailyScheduleCard(
                        viewModel: classtableViewModel,
                        dayIndex: effectiveDayIndex
                    )
                }
            }
        } else {
            animatedCard(delay: 0.1) {
                SignInPromptCard()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupOnAppear() {
        if sessionService.isAuthenticated && sessionService.userInfo == nil {
            sessionService.fetchUserInfo { _, _ in }
        }
        if sessionService.isAuthenticated {
            isLoading = true
            classtableViewModel.fetchYears()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
        if !hasAnimatedOnce {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateCards = true
                    hasAnimatedOnce = true
                }
            }
        } else {
            animateCards = true
        }
    }
    
    private func handleYearsChange(_ years: [Year]) {
        if !years.isEmpty && !classtableViewModel.selectedYearId.isEmpty {
            classtableViewModel.fetchTimetable()
        } else if !years.isEmpty {
            classtableViewModel.selectedYearId = years.first!.W_YearID
            classtableViewModel.fetchTimetable()
        }
    }
    
    private func handleAuthChange(_ isAuthenticated: Bool) {
        if !isAuthenticated {
            classtableViewModel.timetable = []
            animateCards = false
            hasAnimatedOnce = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateCards = true
                    hasAnimatedOnce = true
                }
            }
        }
    }
    
    private func getNextClassForDay(_ dayIndex: Int, isForToday: Bool) -> (period: ClassPeriod, classData: String, dayIndex: Int, isForToday: Bool)? {
        if isForToday {
            let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod()
            guard let period = periodInfo.period,
                  period.number < classtableViewModel.timetable.count,
                  dayIndex + 1 < classtableViewModel.timetable[period.number].count else { return nil }
            let classData = classtableViewModel.timetable[period.number][dayIndex + 1]
            if classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
            return (period: period, classData: classData, dayIndex: dayIndex, isForToday: true)
        } else {
            for row in 1..<classtableViewModel.timetable.count {
                if row < classtableViewModel.timetable.count && dayIndex + 1 < classtableViewModel.timetable[row].count {
                    let classData = classtableViewModel.timetable[row][dayIndex + 1]
                    if !classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if let period = ClassPeriodsManager.shared.classPeriods.first(where: { $0.number == row }) {
                            return (period: period, classData: classData, dayIndex: dayIndex, isForToday: false)
                        }
                    }
                }
            }
            return nil
        }
    }
    
    private func isCurrentDateWeekend() -> Bool {
        if let override = selectedDayOverride {
            return override < 0 || override >= 5
        } else {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: currentTime)
            return weekday == 1 || weekday == 7
        }
    }
    
    private func isHolidayActive() -> Bool {
        if !isHolidayMode {
            return false
        }
        if !holidayHasEndDate {
            return true
        }
        let calendar = Calendar.current
        let currentDay = calendar.startOfDay(for: currentTime)
        let endDay = calendar.startOfDay(for: holidayEndDate)
        return currentDay <= endDay
    }
}
