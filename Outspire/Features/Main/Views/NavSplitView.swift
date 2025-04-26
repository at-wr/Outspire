import SwiftUI
#if !targetEnvironment(macCatalyst)
import ColorfulX
#endif

struct NavSplitView: View {
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var urlSchemeHandler: URLSchemeHandler
    @EnvironmentObject var gradientManager: GradientManager // Add gradient manager
    @State private var selectedLink: String? = "today"
    @State private var refreshID = UUID()
    @State private var showOnboardingSheet = false
    @State private var hasCheckedOnboarding = false
    @AppStorage("lastVersionRun") private var lastVersionRun: String?
    @State private var onboardingCompleted = false
    @Environment(\.colorScheme) private var colorScheme // Add colorScheme

    var body: some View {
        NavigationSplitView {
            ZStack {
#if !targetEnvironment(macCatalyst)
                // Add ColorfulX as background
ColorfulView(
    color: $gradientManager.gradientColors,
    speed: $gradientManager.gradientSpeed,
    noise: $gradientManager.gradientNoise,
    transitionSpeed: $gradientManager.gradientTransitionSpeed
)
.ignoresSafeArea()
.opacity(colorScheme == .dark ? 0.15 : 0.3) // Reduce opacity more in dark mode

// Semi-transparent background for better contrast
Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7)
    .ignoresSafeArea()
#endif

                // Existing list content with better background
                List(selection: $selectedLink) {
                    NavigationLink(value: "today") {
                        Label("Today", systemImage: "text.rectangle.page")

                    }

                    NavigationLink(value: "classtable") {
                        Label("Classtable", systemImage: "clock.badge.questionmark")
                    }

                    if !Configuration.hideAcademicScore {
                        NavigationLink(value: "score") {
                            Label("Academic Grades", systemImage: "pencil.and.list.clipboard")
                        }
                    }

                    Section {
                        NavigationLink(value: "club-info") {
                            Label("Hall of Clubs", systemImage: "person.2.circle")
                        }
                        NavigationLink(value: "club-activity") {
                            Label("Activity Records", systemImage: "checklist")
                        }
                    } header: {
                        Text("Activities")
                    }

                    Section {
                        NavigationLink(value: "map") {
                            Label("Campus Map", systemImage: "map")
                        }
                        NavigationLink(value: "school-arrangement") {
                            Label("School Arrangements", systemImage: "calendar.badge.clock")
                        }
                        NavigationLink(value: "lunch-menu") {
                            Label("Dining Menus", systemImage: "fork.knife")
                        }
#if DEBUG
                        NavigationLink(value: "help") {
                            Label("Help", systemImage: "questionmark.circle.dashed")
                        }
#endif
                    } header: {
                        Text("Miscellaneous")
                    }
                }
                .scrollContentBackground(.hidden) // Hide the default List background
                .background(Color.clear) // Make the background transparent
                .modifier(NavigationColumnWidthModifier()) // Apply column width correctly
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            settingsManager.showSettingsSheet.toggle()
                        }) {
                            Image(systemName: "gear")
                        }

                    }
                }
                .navigationTitle("Outspire")
                .toolbarBackground(Color(UIColor.secondarySystemBackground))
                .contentMargins(.vertical, 10)
                .sheet(isPresented: $settingsManager.showSettingsSheet) {
                    SettingsView(showSettingsSheet: $settingsManager.showSettingsSheet)
                        .onDisappear {
                            refreshID = UUID()
                        }
                }
                .sheet(isPresented: $showOnboardingSheet) {
                    OnboardingView(isPresented: $showOnboardingSheet)
                        .onDisappear {
                            checkOnboardingStatus()
                        }
                }
            }
        } detail: {
            detailView
        }
        .onChange(of: Configuration.hideAcademicScore) { newValue in
            if newValue && selectedLink == "score" {
                selectedLink = "today"
            }
            refreshID = UUID()
        }
        // Add URL scheme handling changes
        .onChange(of: urlSchemeHandler.navigateToToday) { newValue in
            if newValue {
                selectedLink = "today"
            }
        }
        .onChange(of: urlSchemeHandler.navigateToClassTable) { newValue in
            if newValue {
                selectedLink = "classtable"
            }
        }
        .onChange(of: urlSchemeHandler.navigateToClub) { clubId in
            if clubId != nil {
                selectedLink = "club-info"
            }
        }
        .onChange(of: urlSchemeHandler.navigateToAddActivity) { clubId in
            if clubId != nil {
                selectedLink = "club-activity"
            }
        }
        .id(refreshID)
        .task {
            checkOnboardingStatus()
        }
        .onChange(of: selectedLink) { _, newLink in
            // Update gradient when the selected view changes
            updateGradientForSelectedLink(newLink)
        }
        .onAppear {
            // Initialize gradient based on current view
            updateGradientForSelectedLink(selectedLink)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        // Use a switch with explicit NavigationStack wrapped views for better tab switching
        switch selectedLink {
        case "today":
            NavigationStack {
                TodayView()
            }
            .id("nav-today")
        case "classtable":
            NavigationStack {
                ClasstableView()
            }
            .id("nav-classtable")
        case "score":
            NavigationStack {
                ScoreView()
            }
            .id("nav-score")
        case "club-info":
            NavigationStack {
                ClubInfoView()
            }
            .id("nav-club-info")
        case "club-activity":
            NavigationStack {
                ClubActivitiesView()
            }
            .id("nav-club-activity")
        case "school-arrangement":
            NavigationStack {
                SchoolArrangementView()
            }
            .id("nav-school-arrangement")
        case "lunch-menu":
            NavigationStack {
                LunchMenuView()
            }
            .id("nav-lunch-menu")
        case "help":
            NavigationStack {
                HelpView()
            }
            .id("nav-help")
        case "map":
            NavigationStack {
                MapView()
            }
            .id("nav-map")
        default:
            NavigationStack {
                TodayView()
            }
            .id("nav-default")
        }
    }

    private func checkOnboardingStatus() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let thresholdVersion = "0.5.1"

        if shouldShowOnboardingForVersion(lastVersionRun: lastVersionRun, thresholdVersion: thresholdVersion) {
            showOnboardingSheet = true
            lastVersionRun = currentVersion
            print("Showing onboarding due to version check.")
        } else if !hasCheckedOnboarding {
            hasCheckedOnboarding = true

            if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                showOnboardingSheet = true
                print("Showing onboarding because 'hasCompletedOnboarding' is false.")
            } else {
                print("'hasCompletedOnboarding' is already true. Onboarding will not be shown.")

            }
        }
    }

    private func shouldShowOnboardingForVersion(lastVersionRun: String?, thresholdVersion: String) -> Bool {
        guard let lastVersion = lastVersionRun else {
            return true
        }
        return lastVersion.compare(thresholdVersion, options: .numeric) == .orderedAscending
    }

    // Update the method to update gradient based on selected link
    private func updateGradientForSelectedLink(_ link: String?) {
        guard let link = link else {
            // Default to today view gradient
            gradientManager.updateGradientForView(.today, colorScheme: colorScheme)
            return
        }

        // For Today view, we need to check the actual context
        if link == "today" {
            // Today view handles context-specific gradients in its own view
            let isWeekend = TodayViewHelpers.isCurrentDateWeekend()
            let isHoliday = Configuration.isHolidayMode

            if !sessionService.isAuthenticated {
                gradientManager.updateGradientForContext(context: .notSignedIn, colorScheme: colorScheme)
            } else if isHoliday {
                gradientManager.updateGradientForContext(context: .holiday, colorScheme: colorScheme)
            } else if isWeekend {
                gradientManager.updateGradientForContext(context: .weekend, colorScheme: colorScheme)
            } else {
                // Let the Today view handle this in its own onAppear
                gradientManager.updateGradientForContext(context: .normal, colorScheme: colorScheme)
            }
        } else {
            // For other views, check if we have an active context
            if gradientManager.currentContext.isSpecialContext {
                // Keep the current context colors but update animation settings
                gradientManager.updateGradientForView(ViewType(fromLink: link) ?? .today, colorScheme: colorScheme)
            } else {
                // No special context, use regular view settings
                gradientManager.updateGradientForView(ViewType(fromLink: link) ?? .today, colorScheme: colorScheme)
            }
        }
    }
}

// MARK: - Navigation Column Width Modifier
struct NavigationColumnWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        #if targetEnvironment(macCatalyst)
        // Use NavigationSplitViewVisibility instead of width for more consistent behavior
        content
            .navigationSplitViewColumnWidth(min: 180, ideal: 180, max: 300)
            .onAppear {
                // Apply AppKit-specific customizations for Mac Catalyst
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.titlebar?.titleVisibility = .visible
                    windowScene.titlebar?.toolbar?.isVisible = true

                    // Override Mac Catalyst settings for better appearance
                    let sidebarAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [UISplitViewController.self])
                    sidebarAppearance.scrollEdgeAppearance = UINavigationBarAppearance()
                    sidebarAppearance.compactAppearance = UINavigationBarAppearance()
                    sidebarAppearance.standardAppearance = UINavigationBarAppearance()

                    // Set sidebar background to clear
                    UITableView.appearance().backgroundColor = .clear
                }
            }
        #else
        // On iOS/iPadOS, use regular settings
        content
            .if(horizontalSizeClass == .regular) { view in
                // Only on iPad, set default width
                view.navigationSplitViewColumnWidth(250)
            }
        #endif
    }
}
