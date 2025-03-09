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
    @State private var selectedDayOverride: Int? = Configuration.selectedDayOverride
    @State private var isHolidayMode: Bool = false
    @State private var isSettingsSheetPresented: Bool = false
    @State private var holidayEndDate: Date = Date().addingTimeInterval(86400)
    @State private var holidayHasEndDate: Bool = false
    @State private var setAsToday: Bool = Configuration.setAsToday
    @State private var allowAnimation = true
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                contentView
            }
        }
        .navigationTitle("Today @ WFLA")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                scheduleButton
            }
        }
        .sheet(isPresented: $isSettingsSheetPresented) {
            scheduleSettingsSheet
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
        .onChange(of: selectedDayOverride) { _, newValue in
            // Save the selected day override to Configuration
            Configuration.selectedDayOverride = newValue
        }
        .onChange(of: setAsToday) { _, newValue in
            // Save the setAsToday setting to Configuration
            Configuration.setAsToday = newValue
        }
        .id("todayView-\(sessionService.isAuthenticated)")
    }
    
    // MARK: - Components
    private var contentView: some View {
        VStack(spacing: 20) {
            headerView
            mainContentView
            Spacer(minLength: 60)
        }
        .padding(.top, 10)
    }
    
    private var scheduleButton: some View {
        Button {
            isSettingsSheetPresented = true
        } label: {
            Image(systemName: "calendar.badge.clock")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(selectedDayOverride != nil || isHolidayMode ? .blue : .primary)
        }
    }
    
    private var scheduleSettingsSheet: some View {
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
    
    // MARK: - Subviews
    private var headerView: some View {
        HeaderView(
            greeting: greeting,
            formattedDate: formattedDate,
            nickname: sessionService.userInfo?.nickname,
            selectedDayOverride: selectedDayOverride,
            isHolidayActive: isHolidayActive(),
            holidayHasEndDate: holidayHasEndDate,
            holidayEndDateString: holidayEndDateString,
            isHolidayMode: isHolidayMode,
            animateCards: animateCards
        )
    }
    
    private var mainContentView: some View {
        MainContentView(
            isAuthenticated: sessionService.isAuthenticated,
            isHolidayActive: isHolidayActive(),
            isLoading: isLoading,
            upcomingClassInfo: upcomingClassInfo,
            assemblyTime: assemblyTime,
            arrivalTime: arrivalTime,
            isCurrentDateWeekend: isCurrentDateWeekend(),
            isHolidayMode: isHolidayMode,
            holidayHasEndDate: holidayHasEndDate, 
            holidayEndDate: holidayEndDate,
            classtableViewModel: classtableViewModel,
            effectiveDayIndex: effectiveDayIndex,
            currentTime: currentTime,
            setAsToday: setAsToday,
            selectedDayOverride: selectedDayOverride,
            animateCards: animateCards,
            effectiveDate: effectiveDateForSelectedDay
        )
    }
    
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
    
    // MARK: - Helper Methods
    private func setupOnAppear() {
        checkForDateChange()
        
        if sessionService.isAuthenticated && sessionService.userInfo == nil {
            sessionService.fetchUserInfo { _, _ in }
        }
        if sessionService.isAuthenticated {
            isLoading = true
            classtableViewModel.fetchYears()
        }
        
        // Timer to update current time every second
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
        
        // Only animate if this is the first launch of app (per session)
        if !AnimationManager.shared.hasShownTodayViewAnimation {
            animateCards = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateCards = true
                    AnimationManager.shared.markTodayViewAnimationShown()
                }
            }
        } else {
            // If we've already shown the animation, just set cards as visible
            animateCards = true
        }
    }
    
    // Check if we need to reset the selected day override
    private func checkForDateChange() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastLaunch = Configuration.lastAppLaunchDate {
            let lastLaunchDay = calendar.startOfDay(for: lastLaunch)
            
            // Reset settings if this is a new day
            if !calendar.isDate(today, inSameDayAs: lastLaunchDay) {
                selectedDayOverride = nil
                setAsToday = false
                Configuration.selectedDayOverride = nil
                Configuration.setAsToday = false
            }
        }
        
        // Update last app launch date
        Configuration.lastAppLaunchDate = Date()
    }
    
    private var effectiveDateForSelectedDay: Date? {
        guard setAsToday, let override = selectedDayOverride else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Calculate target weekday (1 = Sunday, 2 = Monday, etc.)
        // Our override is 0-based (0 = Monday), so we need to add 2
        let targetWeekday = override + 2
        
        // Calculate days to add/subtract to get from current weekday to target weekday
        var daysToAdd = targetWeekday - currentWeekday
        
        // Adjust to get the closest occurrence (past or future)
        if daysToAdd > 3 {
            daysToAdd -= 7  // Go back a week if more than 3 days ahead
        } else if daysToAdd < -3 {
            daysToAdd += 7  // Go forward a week if more than 3 days behind
        }
        
        // Create a new date that represents the target weekday but with current time
        return calendar.date(byAdding: .day, value: daysToAdd, to: now)
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
            
            // Only animate if this is the first time in the session
            if !AnimationManager.shared.hasShownTodayViewAnimation {
                animateCards = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateCards = true
                        AnimationManager.shared.markTodayViewAnimationShown()
                    }
                }
            } else {
                animateCards = true
            }
        }
    }
    
    private func getNextClassForDay(_ dayIndex: Int, isForToday: Bool) -> (period: ClassPeriod, classData: String, dayIndex: Int, isForToday: Bool)? {
        // If we're using "Set as Today" mode with a selected day
        if setAsToday && selectedDayOverride != nil {
            let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod()
            guard let period = periodInfo.period,
                  period.number < classtableViewModel.timetable.count,
                  dayIndex + 1 < classtableViewModel.timetable[period.number].count else { return nil }
            
            let classData = classtableViewModel.timetable[period.number][dayIndex + 1]
            if classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
            
            return (period: period, classData: classData, dayIndex: dayIndex, isForToday: true)
        } 
        // Normal "today" mode
        else if isForToday {
            let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod()
            guard let period = periodInfo.period,
                  period.number < classtableViewModel.timetable.count,
                  dayIndex + 1 < classtableViewModel.timetable[period.number].count else { return nil }
            
            let classData = classtableViewModel.timetable[period.number][dayIndex + 1]
            if classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
            
            return (period: period, classData: classData, dayIndex: dayIndex, isForToday: true)
        } 
        // Preview mode for other days
        else {
            // Find the first class of the day when viewing other days
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

// MARK: - Supporting Views
struct HeaderView: View {
    let greeting: String
    let formattedDate: String
    let nickname: String?
    let selectedDayOverride: Int?
    let isHolidayActive: Bool
    let holidayHasEndDate: Bool
    let holidayEndDateString: String
    let isHolidayMode: Bool
    let animateCards: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let nickname = nickname {
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
        .animation(
            .spring(response: 0.7, dampingFraction: 0.8),
            value: animateCards
        )
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
        } else if isHolidayActive && holidayHasEndDate {
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
}

struct MainContentView: View {
    let isAuthenticated: Bool
    let isHolidayActive: Bool
    let isLoading: Bool
    let upcomingClassInfo: (period: ClassPeriod, classData: String, dayIndex: Int, isForToday: Bool)?
    let assemblyTime: String
    let arrivalTime: String
    let isCurrentDateWeekend: Bool
    let isHolidayMode: Bool
    let holidayHasEndDate: Bool
    let holidayEndDate: Date
    let classtableViewModel: ClasstableViewModel
    let effectiveDayIndex: Int
    let currentTime: Date
    let setAsToday: Bool
    let selectedDayOverride: Int?
    let animateCards: Bool
    let effectiveDate: Date?
    
    var body: some View {
        if isAuthenticated {
            authenticatedContent
        } else {
            animatedCard(delay: 0.1) {
                SignInPromptCard()
            }
        }
    }
    
    @ViewBuilder
    private var authenticatedContent: some View {
        if isHolidayActive {
            animatedCard(delay: 0.1) {
                HolidayModeCard(hasEndDate: holidayHasEndDate, endDate: holidayEndDate)
            }
        } else if isLoading {
            animatedCard(delay: 0.1) {
                UpcomingClassSkeletonView()
            }
        } else if let upcoming = upcomingClassInfo {
            upcomingClassView(upcoming: upcoming)
        } else {
            noClassContent
        }
        
        // Always show these cards
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
    }
    
    @ViewBuilder
    private var noClassContent: some View {
        if isCurrentDateWeekend {
            animatedCard(delay: 0.1) {
                WeekendCard()
            }
        } else {
            animatedCard(delay: 0.1) {
                NoClassCard()
            }
        }
    }
    
    @ViewBuilder
    private func upcomingClassView(upcoming: (period: ClassPeriod, classData: String, dayIndex: Int, isForToday: Bool)) -> some View {
        animatedCard(delay: 0.1) {
            EnhancedClassCard(
                day: TodayViewHelpers.weekdayName(for: upcoming.dayIndex + 1),
                period: upcoming.period,
                classData: upcoming.classData,
                currentTime: currentTime,
                isForToday: upcoming.isForToday,
                setAsToday: setAsToday && selectedDayOverride != nil,
                effectiveDate: setAsToday && selectedDayOverride != nil ? effectiveDate : nil
            )
        }
    }
    
    @ViewBuilder
    private func animatedCard<Content: View>(delay: Double, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal)
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(
                .spring(response: 0.7, dampingFraction: 0.8)
                .delay(delay),
                value: animateCards
            )
    }
}
