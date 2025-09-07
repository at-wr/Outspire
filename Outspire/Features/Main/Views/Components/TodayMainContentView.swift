import SwiftUI
import CoreLocation

struct TodayMainContentView: View {
    let isAuthenticated: Bool
    let isHolidayActive: Bool
    let isLoading: Bool
    let upcomingClassInfo:
        (period: ClassPeriod, classData: String, dayIndex: Int, isForToday: Bool)?
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

    private func animatedCard<Content: View>(
        delay: Double, @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        content()
            .padding(.horizontal)
    }

    @ViewBuilder
    private var authenticatedContent: some View {
        // Fixed-size VStack with spacing to prevent jittering
        VStack(spacing: 20) {
            // Main class card with fixed height to prevent layout shifts
            ZStack {
                if isHolidayActive {
                    HolidayModeCard(hasEndDate: holidayHasEndDate, endDate: holidayEndDate)
                } else if isLoading {
                    UpcomingClassSkeletonView()
                } else if let upcoming = upcomingClassInfo {
                    ClassSummaryCard(
                        day: TodayViewHelpers.weekdayName(for: upcoming.dayIndex + 1),
                        period: upcoming.period,
                        classData: upcoming.classData,
                        isForToday: upcoming.isForToday
                    )
                } else if isCurrentDateWeekend {
                    WeekendCard()
                } else if areClassesOverForToday() {
                    NoClassCard(isDimmed: true)
                } else {
                    NoClassCard()
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.97)).animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)),
                                removal: .opacity.animation(.easeOut(duration: 0.25))
                            )
                        )
                }
            }
            .padding(.horizontal)

            // Quick links to common sections
            QuickLinksCard()
                .padding(.horizontal)

            // Show the schedule card
            DailyScheduleCard(
                viewModel: classtableViewModel,
                dayIndex: effectiveDayIndex
            )
            .padding(.horizontal)
        }
        .glassContainer(spacing: 16)
    }

    @ViewBuilder
    private var notAuthenticatedContent: some View {
        SignInPromptCard()
            .padding(.horizontal)
    }

    private func shouldShowTravelInfo() -> Bool {
        // Show travel info if user is not near school and we have travel data
        guard locationManager.userLocation != nil,
            locationManager.authorizationStatus == .authorizedWhenInUse
                || locationManager.authorizationStatus == .authorizedAlways,
            travelTimeToSchool != nil,
            travelDistance != nil
        else {
            return false
        }
        return !locationManager.isNearSchool()
    }

    // Method to check if all classes for today are over
    private func areClassesOverForToday() -> Bool {
        // Only check this for weekdays
        guard !isCurrentDateWeekend, !isHolidayActive, effectiveDayIndex >= 0,
            effectiveDayIndex <= 4
        else {
            return false
        }

        let now = Date()

        // Get the last period of the day
        if let lastClassPeriod = ClassPeriodsManager.shared.classPeriods.last?.number,
            let timetable = classtableViewModel.timetable.isEmpty
                ? nil : classtableViewModel.timetable,
            !timetable.isEmpty
        {
            // Check if there's any class data for this day
            if effectiveDayIndex + 1 < timetable[min(lastClassPeriod, timetable.count - 1)].count {
                // Check if we have any scheduled classes
                let classes = getScheduledClassesForDay(effectiveDayIndex)
                if !classes.isEmpty, let lastPeriodNumber = classes.map({ $0.0 }).max(),
                    let lastPeriod = ClassPeriodsManager.shared.classPeriods.first(where: {
                        $0.number == lastPeriodNumber
                    })
                {
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
        guard !classtableViewModel.timetable.isEmpty, dayIndex >= 0, dayIndex < 5 else {
            return classes
        }

        for row in 1..<classtableViewModel.timetable.count {
            if row < classtableViewModel.timetable.count
                && dayIndex + 1 < classtableViewModel.timetable[row].count
            {
                let classData = classtableViewModel.timetable[row][dayIndex + 1]
                if !classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    classes.append((row, classData))
                }
            }
        }
        return classes
    }
}
