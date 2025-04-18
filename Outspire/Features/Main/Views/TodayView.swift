import SwiftUI
import Foundation
import CoreLocation
import WeatherKit
#if !targetEnvironment(macCatalyst)
import ColorfulX
#endif
import TipKit

// Define a tip for the schedule button on TodayView
struct ScheduleTip: Tip {
    var title: Text {
        Text("Your Schedule Settings")
    }
    var message: Text? {
        Text("Tap here to adjust today's schedule settings.")
    }
    var image: Image? {
        Image(systemName: "calendar.badge.clock")
    }
}

struct TodayView: View {
    // MARK: - Environment & State
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var classtableViewModel = ClasstableViewModel()
    // Use the shared instance for LocationManager
    @ObservedObject private var locationManager = LocationManager.shared
    // Use the shared instance for RegionChecker
    @ObservedObject private var regionChecker = RegionChecker.shared
    // Add URL scheme handler environment object
    @EnvironmentObject var urlSchemeHandler: URLSchemeHandler
    @EnvironmentObject var gradientManager: GradientManager // Add gradient manager

    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var isLoading = false
    @State private var animateCards = false
    @State private var selectedDayOverride: Int? = Configuration.selectedDayOverride
    @State private var isHolidayMode: Bool = Configuration.isHolidayMode
    @State private var isSettingsSheetPresented: Bool = false
    @State private var holidayEndDate: Date = Configuration.holidayEndDate
    @State private var holidayHasEndDate: Bool = Configuration.holidayHasEndDate
    @State private var setAsToday: Bool = Configuration.setAsToday
    @State private var allowAnimation = true
    @State private var forceUpdate: Bool = false  // Added to force UI updates
    @State private var showLocationUpdateSheet = false
    @State private var showScheduleTip: Bool = false
    @State private var skipTip: Bool = false
    @AppStorage("hasShownScheduleTip") private var hasShownScheduleTip: Bool = false

@StateObject private var weatherManager = WeatherManager.shared
    // Track if we've already started a Live Activity for the current class
    @State private var hasStartedLiveActivity = false
    @State private var activeClassLiveActivities: [String: Bool] = [:]
    // Add this state variable to track returning from sheets
    @State private var isReturningFromSheet = false

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body
    var body: some View {
        ZStack {
#if !targetEnvironment(macCatalyst)
            // Use the shared ColorfulX view
            ColorfulView(
                color: $gradientManager.gradientColors,
                speed: $gradientManager.gradientSpeed,
                noise: $gradientManager.gradientNoise,
                transitionSpeed: $gradientManager.gradientTransitionSpeed
            )
            .ignoresSafeArea()
            .opacity(0.2) // Reduce opacity to make content readable

            // Semi-transparent white background to ensure content readability
            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7)
                .ignoresSafeArea()
#endif

            ScrollView {
                contentView
            }
        }
        .navigationTitle("Today @ WFLA")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar) // This works with our custom appearances
        .scrollIndicators(.hidden)

        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                scheduleButton
            }
        }
        .sheet(isPresented: $isSettingsSheetPresented, onDismiss: {
            // Mark that we're returning from a sheet and skip tip on next onAppear
            isReturningFromSheet = true
            skipTip = true

            // Immediately set animateCards to true without animation
            // This is critical to prevent the animation from running again
            animateCards = true

            // Update gradient colors based on current state
            updateGradientColors()
        }) {
            scheduleSettingsSheet
                .environmentObject(sessionService) // Explicitly pass the SessionService to fix Mac Catalyst crash
        }
        .onAppear {
            setupOnAppear()
            customizeNavigationBarAppearance()
            updateGradientColors() // Still call this to update shared gradient

            if let location = locationManager.userLocation {
                Task {
                    await weatherManager.fetchWeather(for: location)
                }
            }
            // Additional fetch to update weather if the initial fetch hasn't updated (avoids showing the placeholder)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if weatherManager.currentTemperature == "--", let location = locationManager.userLocation {
                    Task {
                        await weatherManager.fetchWeather(for: location)
                    }
                }
            }

            if sessionService.isAuthenticated && !skipTip && !hasShownScheduleTip {
                // Delay tip appearance for 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showScheduleTip = true
                    // Auto-hide the tip after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showScheduleTip = false
                        // Set the flag to prevent showing the tip again
                        hasShownScheduleTip = true
                    }
                }
            }
            // Do not automatically reset skipTip here; once the settings sheet is dismissed, the tip should remain suppressed.
            // Check for URL scheme navigation to today view
            if urlSchemeHandler.navigateToToday {
                // Reset the handler state after navigation is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    urlSchemeHandler.navigateToToday = false
                }
            }
        }
        .onDisappear {
            saveSettings()
            timer?.invalidate()
            timer = nil
            NotificationCenter.default.removeObserver(self, name: .locationSignificantChange, object: nil)
        }
        .onChange(of: classtableViewModel.years) { _, years in
            handleYearsChange(years)
        }
        .onChange(of: classtableViewModel.isLoadingTimetable) { _, isLoading in
            self.isLoading = isLoading
        }
        .onChange(of: sessionService.isAuthenticated) { _, isAuthenticated in
            handleAuthChange(isAuthenticated)
            updateGradientColors() // Update gradient when authentication changes
            if isAuthenticated {
                skipTip = true
            }
        }
        .onChange(of: selectedDayOverride) { newValue in
            // Save the selected day override to Configuration
            Configuration.selectedDayOverride = newValue
            forceUpdate.toggle() // Force UI update
            updateGradientColors() // Update gradient when selected day changes
            // When day changes, force update of calculations
            if timer == nil {
                // If timer isn't active, create it temporarily
                currentTime = Date() // Force time update
            }
        }
        .onChange(of: setAsToday) { newValue in
            // Save the setAsToday setting to Configuration
            Configuration.setAsToday = newValue
            forceUpdate.toggle() // Force UI update
        }
        .onChange(of: isHolidayMode) { newValue in
            Configuration.isHolidayMode = newValue
            forceUpdate.toggle() // Force UI update
            updateGradientColors() // Update gradient when holiday mode changes
        }
        .onChange(of: holidayHasEndDate) { newValue in
            Configuration.holidayHasEndDate = newValue
        }
        .onChange(of: holidayEndDate) { newValue in
            Configuration.holidayEndDate = newValue
        }
        .onChange(of: colorScheme) { _ in
            // Update gradient when color scheme changes
            updateGradientColors()
        }
        // Add observer for upcomingClassInfo changes
        .onChange(of: upcomingClassInfo?.period.id) { _, _ in
            // When the relevant class period changes, update the Live Activity
            // Use forceCheck to ensure it runs even if the manager thinks an activity exists
            startClassLiveActivityIfNeeded(forceCheck: true)
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            if let location = newLocation {
                Task {
                    await weatherManager.fetchWeather(for: location)
                }
            }
        }
        .id("todayView-\(sessionService.isAuthenticated)-\(forceUpdate)")
        .environment(\.colorScheme, colorScheme)
    }

    // MARK: - Gradient Methods

    // Update gradient colors based on the current state of the app
    private func updateGradientColors() {
        if !sessionService.isAuthenticated {
            gradientManager.updateGradientForContext(context: .notSignedIn, colorScheme: colorScheme)
            return
        }

        if isHolidayActive() {
            gradientManager.updateGradientForContext(context: .holiday, colorScheme: colorScheme)
            return
        }

        if isCurrentDateWeekend() {
            gradientManager.updateGradientForContext(context: .weekend, colorScheme: colorScheme)
            return
        }

        // Determine if we have an upcoming class
        if let upcomingInfo = upcomingClassInfo {
            let isSelfStudy = upcomingInfo.classData.contains("Self-Study")
            let isActive = upcomingInfo.period.isCurrentlyActive()

            if isActive {
                // Currently in a class period
                if isSelfStudy {
                    gradientManager.updateGradientForContext(context: .inSelfStudy, colorScheme: colorScheme)
                } else {
                    gradientManager.updateGradientForContext(
                        context: .inClass(subject: upcomingInfo.classData),
                        colorScheme: colorScheme
                    )
                }
            } else {
                // Upcoming class period
                if isSelfStudy {
                    gradientManager.updateGradientForContext(context: .upcomingSelfStudy, colorScheme: colorScheme)
                } else {
                    gradientManager.updateGradientForContext(
                        context: .upcomingClass(subject: upcomingInfo.classData),
                        colorScheme: colorScheme
                    )
                }
            }
        } else {
            // No upcoming class
            gradientManager.updateGradientForContext(context: .afterSchool, colorScheme: colorScheme)
        }
    }

    private func customizeNavigationBarAppearance() {
        // Configure transparent appearance for expanded state
        let transparentAppearance = UINavigationBarAppearance()
        transparentAppearance.configureWithTransparentBackground()
        transparentAppearance.backgroundColor = .clear
        transparentAppearance.shadowColor = .clear

        // Configure solid appearance for collapsed state
        let solidAppearance = UINavigationBarAppearance()
        solidAppearance.configureWithDefaultBackground()
        solidAppearance.backgroundColor = UIColor.secondarySystemBackground
        solidAppearance.shadowColor = .clear // Still remove shadow if desired

        // Apply transparent appearance when title is large/expanded
        UINavigationBar.appearance().scrollEdgeAppearance = transparentAppearance

        // Apply solid appearance when scrolled/collapsed
        UINavigationBar.appearance().standardAppearance = solidAppearance
        UINavigationBar.appearance().compactAppearance = solidAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = solidAppearance
    }

    // Save all settings on disappear
    private func saveSettings() {
        Configuration.selectedDayOverride = selectedDayOverride
        Configuration.setAsToday = setAsToday
        Configuration.isHolidayMode = isHolidayMode
        Configuration.holidayHasEndDate = holidayHasEndDate
        Configuration.holidayEndDate = holidayEndDate
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
        .disabled(!sessionService.isAuthenticated)
        .opacity(sessionService.isAuthenticated ? 1.0 : 0.5)
        .tipKit(ScheduleTip(), shouldShowTip: showScheduleTip)
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
            animateCards: animateCards,
            weatherSymbol: weatherManager.conditionSymbol,
            weatherTemperature: weatherManager.currentTemperature
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
            effectiveDate: effectiveDateForSelectedDay,
            locationManager: locationManager,
            isInChinaRegion: regionChecker.isChinaRegion(),
            showMapView: shouldShowMapView(),
            travelTimeToSchool: locationManager.travelTimeToSchool,
            travelDistance: locationManager.travelDistance,
            activeClassLiveActivities: activeClassLiveActivities,
            toggleLiveActivity: toggleLiveActivityForCurrentClass
        )
    }

    // MARK: - Computed Properties
    private var formattedDate: String {
        TodayViewHelpers.formatDateString(currentTime)
    }

    var greeting: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
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

        // Calculate class info with accurate time context
        // This ensures we get the right class period without causing unnecessary updates
        return getNextClassForDay(dayIndex, isForToday: isForToday)
    }

    private var holidayEndDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: holidayEndDate)
    }

    private var effectiveDateForSelectedDay: Date? {
        guard setAsToday, let override = selectedDayOverride else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)

        // Calculate target weekday (1 = Sunday, 2 = Monday, etc.)
        // Our override is 0-based (0 = Monday), so we need to add 2
        let targetWeekday = override + 2

        // If it's the same day of the week, just use today's date
        // This prevents the "next week" issue when selecting current weekday
        if targetWeekday == currentWeekday {
            return now
        }

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

    // MARK: - Helper Methods
    private func setupOnAppear() {
        checkForDateChange()

        // Ensure that on first app launch we're not selecting any specific day
        if AnimationManager.shared.isFirstLaunch {
            selectedDayOverride = nil
            setAsToday = false
            Configuration.selectedDayOverride = nil
            Configuration.setAsToday = false
        }

        if sessionService.isAuthenticated && sessionService.userInfo == nil {
            sessionService.fetchUserInfo { _, _ in }
        }
        if sessionService.isAuthenticated {
            isLoading = true
            classtableViewModel.fetchYears()
        }

        // Setup location services and region check - only once on appear
        setupLocationServices()

        // Setup notifications
        setupNotifications()

        // Timer to update current time - optimized to reduce unnecessary refreshes
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            self.currentTime = Date()
            let second = Calendar.current.component(.second, from: self.currentTime)
            // Refresh weather every 30 seconds or when a class transition is detected
            if second % 30 == 0 || self.checkForClassTransition() {
                self.forceUpdate.toggle()
                if let location = locationManager.userLocation {
                    Task {
                        await weatherManager.fetchWeather(for: location)
                    }
                }
            }
        }

        // Handle animations differently depending on context
        if AnimationManager.shared.isFirstLaunch {
            // First launch - delay animation for a smooth experience
            animateCards = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animateCards = true
                    AnimationManager.shared.markAppLaunched()
                }
            }
        } else if isReturningFromSheet {
            // When returning from a sheet, DON'T trigger any animations
            // The animateCards value is already set to true in the onDismiss callback
            // Just reset the flag for next time
            isReturningFromSheet = false
        } else {
            // Normal appearance - animate the cards
            animateCards = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateCards = true
            }
        }

        NotificationCenter.default.addObserver(
            forName: .locationSignificantChange,
            object: nil,
            queue: .main) { _ in
                self.regionChecker.fetchRegionCode()
            }

        // Start Live Activity for the current class if available
        startClassLiveActivityIfNeeded()
    }

    // Add this method to setup notifications
    private func setupNotifications() {
        // Only schedule notifications if onboarding is completed
        // (Permissions are handled by onboarding now)
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if hasCompletedOnboarding {
            NotificationManager.shared.checkAuthorizationStatus { status in
                if status == .authorized {
                    // Schedule the morning ETA notification
                    NotificationManager.shared.scheduleMorningETANotification()
                }
            }
        }
    }

    private func setupLocationServices() {
        // Check time of day - only enable location between 5AM and 3PM
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let shouldCheckLocation = hour >= 5 && hour < 15

        if shouldCheckLocation {
            // Fetch region code once - don't do this repeatedly
            if regionChecker.regionCode == nil {
                regionChecker.fetchRegionCode()
            }

            // Only start location services if already authorized
            // (Permissions are handled by onboarding now)
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()

                // Calculate ETA only once on appear, not continuously
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateTravelTime()
                }
            }
        }
    }

    private func updateTravelTime() {
        // Only calculate ETA if we're within the right time frame
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let shouldCheckLocation = hour >= 5 && hour < 15

        guard shouldCheckLocation else { return }

        // Use a separate property for map updates to prevent jittering
        locationManager.calculateETAToSchool(isInChina: regionChecker.isChinaRegion()) {
            // Force refresh the view when travel time updates
            /*
             DispatchQueue.main.async { [self] in
             self.forceUpdate.toggle()
             }
             */
        }
    }

    private func shouldShowMapView() -> Bool {
        // If debug override is enabled, respect its value
        if Configuration.debugOverrideMapView {
            return Configuration.debugShowMapView
        }

        // Check if user location is available and authorized
        guard let _ = locationManager.userLocation,
              locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways else {
            return false
        }

        // If user is at school and has chosen to hide map there, respect that setting
        if locationManager.isNearSchool() && Configuration.manuallyHideMapAtSchool {
            return false
        }

        // Otherwise, always show the map
        return true
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

            // Reset all schedule settings when logged out
            selectedDayOverride = nil
            setAsToday = false
            isHolidayMode = false

            // Also reset in Configuration to ensure persistence
            Configuration.selectedDayOverride = nil
            Configuration.setAsToday = false
            Configuration.isHolidayMode = false

            // No animation when switching between views
            animateCards = true
        }
    }

    // Update the getNextClassForDay function to handle self-study periods
    private func getNextClassForDay(_ dayIndex: Int, isForToday: Bool) -> (period: ClassPeriod, classData: String, dayIndex: Int, isForToday: Bool)? {
        // If we're using "Set as Today" mode with a selected day
        if setAsToday && selectedDayOverride != nil {
            let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod(useEffectiveDate: true,
                                                                               effectiveDate: effectiveDateForSelectedDay)
            return getClassForPeriod(periodInfo, dayIndex: dayIndex, isForToday: true)
        }
        // Normal "today" mode
        else if isForToday {
            let periodInfo = ClassPeriodsManager.shared.getCurrentOrNextPeriod()
            return getClassForPeriod(periodInfo, dayIndex: dayIndex, isForToday: true)
        }
        // Preview mode for other days
        else {
            // Find the first class of the day when viewing other days
            for row in 1..<classtableViewModel.timetable.count {
                if row < classtableViewModel.timetable.count && dayIndex + 1 < classtableViewModel.timetable[row].count {
                    let classData = classtableViewModel.timetable[row][dayIndex + 1]
                    let isSelfStudy = classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                    if let period = ClassPeriodsManager.shared.classPeriods.first(where: { $0.number == row }) {
                        // For self-study periods, we still show the period but mark it as self-study
                        if isSelfStudy {
                            return (period: period, classData: "You\nSelf-Study", dayIndex: dayIndex, isForToday: false)
                        } else {
                            return (period: period, classData: classData, dayIndex: dayIndex, isForToday: false)
                        }
                    }
                }
            }
            return nil
        }
    }

    private func getClassForPeriod(_ periodInfo: (period: ClassPeriod?, isCurrentlyActive: Bool),
                                   dayIndex: Int, isForToday: Bool) -> (period: ClassPeriod, classData: String, dayIndex: Int, isForToday: Bool)? {
        guard let period = periodInfo.period,
              period.number < classtableViewModel.timetable.count,
              dayIndex + 1 < classtableViewModel.timetable[period.number].count else { return nil }

        var classData = classtableViewModel.timetable[period.number][dayIndex + 1]
        let isSelfStudy = classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // If it's self-study, provide a placeholder
        if isSelfStudy {
            classData = "You\nSelf-Study"
        }

        return (period: period, classData: classData, dayIndex: dayIndex, isForToday: isForToday)
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

    // Add helper method to detect class period changes
    private func shouldRefreshClassInfo() -> Bool {
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: Date())
        let currentSecond = calendar.component(.second, from: Date())

        // Check if we're at an exact class change time (0 seconds)
        // Add common class change minutes to this array
        let classChangeMinutes = [0, 5, 45, 35, 15, 30, 10, 55]

        // Check if we're close to the end of a period (last 10 seconds)
        if let upcoming = upcomingClassInfo, upcoming.isForToday && upcoming.period.isCurrentlyActive() {
            let secondsRemaining = upcoming.period.endTime.timeIntervalSince(Date())
            if secondsRemaining <= 10 && secondsRemaining > 0 {
                return true
            }
        }

        return classChangeMinutes.contains(currentMinute) && currentSecond == 0
    }

    // Safer method to detect class transitions
    private func checkForClassTransition() -> Bool {
        // Only check for active periods that are about to end
        if let upcoming = upcomingClassInfo, upcoming.isForToday && upcoming.period.isCurrentlyActive() {
            let secondsRemaining = upcoming.period.endTime.timeIntervalSince(Date())
            // Only trigger refresh for the last 5 seconds of a class period
            if secondsRemaining <= 5 && secondsRemaining > 0 {
                return true
            }

            // Check if we're about to transition, then see if we need to start a Live Activity for the next period
            if secondsRemaining <= 60 && secondsRemaining > 0 && Configuration.automaticallyStartLiveActivities {
                DispatchQueue.main.asyncAfter(deadline: .now() + secondsRemaining + 1) {
                    self.startClassLiveActivityIfNeeded(forceCheck: true)
                }
            }
        }
        return false
    }

    // In the existing startClassLiveActivityIfNeeded method, update to use the enhanced functionality:

    private func startClassLiveActivityIfNeeded(forceCheck: Bool = false) {
    #if !targetEnvironment(macCatalyst)
        // Don't start Live Activity if holiday mode is active
        guard !isHolidayActive() else { return }

        // Only process when we have class info and timetable data
        guard let upcoming = upcomingClassInfo,
              !classtableViewModel.timetable.isEmpty else { return }

        // Create a unique ID for this class period
        let activityId = "\(upcoming.period.number)_\(upcoming.classData)"

        // Skip if we've already started a Live Activity for this specific class period
        // unless we're explicitly forcing a check
        if !forceCheck && activeClassLiveActivities[activityId] == true {
            return
        }

        // Process the class data to extract required information
        let components = upcoming.classData.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }

        // Only proceed if we have enough data
        guard components.count >= 2 else { return }

        let teacherName = components.count > 0 ? components[0] : "Unknown Teacher"
        let className = components.count > 1 ? components[1] : "Unknown Class"
        let roomNumber = components.count > 2 ? components[2] : "Unknown Room"

        // Use the enhanced method that handles either creating a new activity or updating existing
        ClassActivityManager.shared.startOrUpdateClassActivity(
            className: className,
            periodNumber: upcoming.period.number,
            roomNumber: roomNumber,
            teacherName: teacherName,
            startTime: upcoming.period.startTime,
            endTime: upcoming.period.endTime
        )

        // Mark this specific class period as having an active Live Activity
        activeClassLiveActivities[activityId] = true
    #endif
    }

    // Update the toggleLiveActivityForCurrentClass method to use the new toggle functionality:

    private func toggleLiveActivityForCurrentClass() {
    #if !targetEnvironment(macCatalyst)
        guard let upcoming = upcomingClassInfo else { return }

        let components = upcoming.classData.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }

        // Only proceed if we have enough data
        guard components.count >= 2 else { return }

        let teacherName = components.count > 0 ? components[0] : "Unknown Teacher"
        let className = components.count > 1 ? components[1] : "Unknown Class"
        let roomNumber = components.count > 2 ? components[2] : "Unknown Room"
        let activityId = "\(upcoming.period.number)_\(upcoming.classData)"

        // Use the new toggle functionality
        let isActive = ClassActivityManager.shared.toggleActivityForClass(
            className: className,
            periodNumber: upcoming.period.number,
            roomNumber: roomNumber,
            teacherName: teacherName,
            startTime: upcoming.period.startTime,
            endTime: upcoming.period.endTime
        )

        // Update the active status
        activeClassLiveActivities[activityId] = isActive

        // Give haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: isActive ? 0.7 : 1.0)
    #endif
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
    let weatherSymbol: String
    let weatherTemperature: String

    var body: some View {
        HStack {
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
            Spacer()
                VStack(spacing: 4) {
                    Image(systemName: weatherSymbol)
                        .font(.title2)
                        .symbolRenderingMode(.multicolor)
                    Text(weatherTemperature)
                        .font(.caption)
                }
                .padding(6)
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
    let locationManager: LocationManager
    let isInChinaRegion: Bool
    let showMapView: Bool
    let travelTimeToSchool: TimeInterval?
    let travelDistance: CLLocationDistance?
    let activeClassLiveActivities: [String: Bool]
    let toggleLiveActivity: () -> Void

    // Add state to track travel time updates for animations
    @State private var travelInfoKey = UUID()

    var body: some View {
        if isAuthenticated {
            authenticatedContent
        } else {
            notAuthenticatedContent
        }
    }

    // Helper method for card animations, to make it accessible within this struct
    private func animatedCard<Content: View>(delay: Double, @ViewBuilder content: @escaping () -> Content) -> some View {
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

    @ViewBuilder
    private var authenticatedContent: some View {
        // Fixed-size VStack with spacing to prevent jittering
        VStack(spacing: 20) {
            // Main class card with fixed height to prevent layout shifts
            ZStack {
                if isHolidayActive {
                    HolidayModeCard(hasEndDate: holidayHasEndDate, endDate: holidayEndDate)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)).animation(.spring(response: 0.5, dampingFraction: 0.7)),
                                removal: .opacity.animation(.easeOut(duration: 0.2))
                            )
                        )
                } else if isLoading {
                    UpcomingClassSkeletonView()
                        .transition(
                            .asymmetric(
                                insertion: .opacity.animation(.easeIn(duration: 0.3)),
                                removal: .opacity.animation(.easeOut(duration: 0.2))
                            )
                        )
                } else if let upcoming = upcomingClassInfo {
                    EnhancedClassCard(
                        day: TodayViewHelpers.weekdayName(for: upcoming.dayIndex + 1),
                        period: upcoming.period,
                        classData: upcoming.classData,
                        currentTime: currentTime,
                        isForToday: upcoming.isForToday,
                        setAsToday: setAsToday && selectedDayOverride != nil,
                        effectiveDate: setAsToday && selectedDayOverride != nil ? effectiveDate : nil,
                        hasActiveActivity: activeClassLiveActivities["\(upcoming.period.number)_\(upcoming.classData)"] == true,
                        toggleLiveActivity: toggleLiveActivity
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.97)).animation(.spring(response: 0.5, dampingFraction: 0.7)),
                            removal: .opacity.animation(.easeOut(duration: 0.25))
                        )
                    )
                } else if isCurrentDateWeekend {
                    WeekendCard()
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.97)).animation(.spring(response: 0.5, dampingFraction: 0.7)),
                                removal: .opacity.animation(.easeOut(duration: 0.25))
                            )
                        )
                } else if areClassesOverForToday() {
                    NoClassCard(isDimmed: true)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.97)).animation(.spring(response: 0.5, dampingFraction: 0.7)),
                                removal: .opacity.animation(.easeOut(duration: 0.25))
                            )
                        )
                } else {
                    NoClassCard()
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.97)).animation(.spring(response: 0.5, dampingFraction: 0.7)),
                                removal: .opacity.animation(.easeOut(duration: 0.25))
                            )
                        )
                }
            }
            .padding(.horizontal)
            .id("ClassCardContainer") // Fixed ID to help with animations
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(
                .spring(response: 0.7, dampingFraction: 0.8)
                .delay(0.1),
                value: animateCards
            )

            // Conditionally show map view with user location
            if showMapView {
                SchoolMapView(
                    userLocation: locationManager.userLocation?.coordinate,
                    isInChina: isInChinaRegion
                )
                .padding(.horizontal)
                .offset(y: animateCards ? 0 : 30)
                .opacity(animateCards ? 1 : 0)
                .animation(
                    .spring(response: 0.7, dampingFraction: 0.8)
                    .delay(0.15),
                    value: animateCards
                )
            }

            // Always show these cards
            SchoolInfoCard(
                assemblyTime: assemblyTime,
                arrivalTime: arrivalTime,
                travelInfo: shouldShowTravelInfo() ?
                (travelTime: travelTimeToSchool, distance: travelDistance) : nil,
                isInChina: isInChinaRegion
            )
            .padding(.horizontal)
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(
                .spring(response: 0.7, dampingFraction: 0.8)
                .delay(0.2),
                value: animateCards
            )
            .id(travelInfoKey) // Force view recreation when travel info significantly changes

            // Show the schedule card
            DailyScheduleCard(
                viewModel: classtableViewModel, // Changed parameter name from classtableViewModel to viewModel
                dayIndex: effectiveDayIndex
            )
            .padding(.horizontal)
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(
                .spring(response: 0.7, dampingFraction: 0.8)
                .delay(0.3),
                value: animateCards
            )
        }
    }

    @ViewBuilder
    private var notAuthenticatedContent: some View {
        // Instead of creating a new implementation, use the existing SignInPromptCard
        SignInPromptCard()
            .padding(.horizontal)
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(
                .spring(response: 0.7, dampingFraction: 0.8)
                .delay(0.1),
                value: animateCards
            )
    }

    private func shouldShowTravelInfo() -> Bool {
        // Show travel info if user is not near school and we have travel data
        guard let _ = locationManager.userLocation,
              locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways,
              travelTimeToSchool != nil,
              travelDistance != nil else {
            return false
        }
        return !locationManager.isNearSchool()
    }

    // Method to check if all classes for today are over
    private func areClassesOverForToday() -> Bool {
        // Only check this for weekdays
        guard !isCurrentDateWeekend, !isHolidayActive, effectiveDayIndex >= 0, effectiveDayIndex <= 4 else {
            return false
        }

        let now = Date()

        // Get the last period of the day
        if let lastClassPeriod = ClassPeriodsManager.shared.classPeriods.last?.number,
           let timetable = classtableViewModel.timetable.isEmpty ? nil : classtableViewModel.timetable,
           !timetable.isEmpty {
            // Check if there's any class data for this day
            if effectiveDayIndex + 1 < timetable[min(lastClassPeriod, timetable.count - 1)].count {
                // Check if we have any scheduled classes
                let classes = getScheduledClassesForDay(effectiveDayIndex)
                if !classes.isEmpty, let lastPeriodNumber = classes.map({ $0.0 }).max(),
                   let lastPeriod = ClassPeriodsManager.shared.classPeriods.first(where: { $0.number == lastPeriodNumber }) {
                    // If current time is after the end time of the last class, all classes are over
                    return now > lastPeriod.endTime
                }
            }
        }

        return false
    }

    // Helper to get scheduled classes for a day
    private func getScheduledClassesForDay(_ dayIndex: Int) -> [(Int, String)] {
        var classes: [(Int, String)] = []
        guard !classtableViewModel.timetable.isEmpty, dayIndex >= 0, dayIndex < 5 else { return classes }

        for row in 1..<classtableViewModel.timetable.count {
            if row < classtableViewModel.timetable.count && dayIndex + 1 < classtableViewModel.timetable[row].count {
                let classData = classtableViewModel.timetable[row][dayIndex + 1]
                if !classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    classes.append((row, classData))
                }
            }
        }
        return classes
    }
}
