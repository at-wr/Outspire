import SwiftUI
import TipKit
#if !targetEnvironment(macCatalyst)
import ColorfulX
#endif

// Define the tip for the main navigation
struct NavigationTip: Tip {
    var title: Text {
        Text("Welcome to Outspire")
    }

    var message: Text? {
        Text("Start by signing in with your WFLA Account.")
    }

    var image: Image? {
        Image(systemName: "party.popper.fill")
    }
}

// Define a tip specifically for the settings button
struct SettingsTip: Tip {
    var title: Text {
        Text("Customize Your Experience")
    }

    var message: Text? {
        Text("Tap here to access app settings and personalize your Outspire experience.")
    }

    var image: Image? {
        Image(systemName: "gear")
    }
}

struct TodayTip: Tip {
    var title: Text {
        Text("Your Daily Overview")
    }

    var message: Text? {
        Text("Check here daily for your schedule, announcements, and important updates.")
    }

    var image: Image? {
        Image(systemName: "calendar")
    }
}

// Define a tip to instruct the user to sign in
struct SignInTip: Tip {
    var title: Text {
        Text("Sign in to Outspire")
    }

    var message: Text? {
        Text("Tap here to sign in and access full features.")
    }

    var image: Image? {
        Image(systemName: "person.crop.circle.badge.checkmark")
    }
}

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
    @State private var currentActiveTip: String?
    @State private var onboardingCompleted = false
    @Environment(\.colorScheme) private var colorScheme // Add colorScheme

    // Initialize the tips
    @State private var navigationTip = NavigationTip()
    @State private var settingsTip = SettingsTip()
    @State private var todayTip = TodayTip()
    @State private var signInTip = SignInTip()

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
                            .tipKit(todayTip, shouldShowTip: currentActiveTip == "today")
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
                        .tipKit(settingsTip, shouldShowTip: currentActiveTip == "settings")
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
            await configureTipsAndCheckOnboarding()
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
        switch selectedLink {
        case "today":
            TodayView()
        case "classtable":
            ClasstableView()
        case "score":
            ScoreView()
        case "club-info":
            ClubInfoView()
        case "club-activity":
            ClubActivitiesView()
        case "school-arrangement":
            SchoolArrangementView()
        case "lunch-menu":
            LunchMenuView()
        case "help":
            HelpView()
        case "map":
            MapView()
        default:
            TodayView()
        }
    }

    private func configureTipsAndCheckOnboarding() async {
        do {
            try await Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        } catch {
            print("Failed to configure TipKit: \(error)")
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let thresholdVersion = "0.5.1"

        if shouldShowOnboardingForVersion(lastVersionRun: lastVersionRun, thresholdVersion: thresholdVersion) {
            showOnboardingSheet = true
            lastVersionRun = currentVersion
            print("Showing onboarding due to version check.")
        } else if !hasCheckedOnboarding {
            hasCheckedOnboarding = true

            await MainActor.run {
                if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                    showOnboardingSheet = true
                    print("Showing onboarding because 'hasCompletedOnboarding' is false.")
                } else {
                    print("'hasCompletedOnboarding' is already true. Onboarding will not be shown.")
                    checkOnboardingStatus()
                }
            }
        }
    }

    private func shouldShowOnboardingForVersion(lastVersionRun: String?, thresholdVersion: String) -> Bool {
        guard let lastVersion = lastVersionRun else {
            return true
        }
        return lastVersion.compare(thresholdVersion, options: .numeric) == .orderedAscending
    }

    private func checkOnboardingStatus() {
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            print("Onboarding has been completed, preparing to show tips sequentially")
            onboardingCompleted = true

            if UIDevice.current.userInterfaceIdiom == .phone {
                if !sessionService.isAuthenticated {
                    // For iPhone not logged in: show Today tip, then Sign In tip, then Settings tip
                    DispatchQueue.main.async {
                        self.currentActiveTip = "today"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        self.currentActiveTip = "signin"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                        self.currentActiveTip = "settings"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
                        self.currentActiveTip = nil
                    }
                } else {
                    // For iPhone logged in: show Today tip then Settings tip
                    DispatchQueue.main.async {
                        self.currentActiveTip = "today"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        self.currentActiveTip = "settings"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                        self.currentActiveTip = nil
                    }
                }
            } else {
                // For non-iPhone devices, show only the Settings tip briefly
                DispatchQueue.main.async {
                    self.currentActiveTip = "settings"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.currentActiveTip = nil
                }
            }
        } else {
            print("Onboarding not completed yet")
            self.currentActiveTip = nil
        }
    }

    private func invalidateTips() async {
        await navigationTip.invalidate(reason: .tipClosed)
        await settingsTip.invalidate(reason: .tipClosed)
        await todayTip.invalidate(reason: .tipClosed)
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

// MARK: - TipKit View Extension
extension View {
    func tipKit<T: Tip>(_ tip: T, shouldShowTip: Bool) -> some View {
        self.modifier(TipViewModifier(tip: tip, shouldShowTip: shouldShowTip))
    }
}

// MARK: - TipKit View Modifier
struct TipViewModifier<T: Tip>: ViewModifier {
    let tip: T
    let shouldShowTip: Bool

    func body(content: Content) -> some View {
        if shouldShowTip {
            content.popoverTip(tip)
        } else {
            content
        }
    }
}
