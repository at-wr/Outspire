import SwiftUI
import TipKit
import ColorfulX

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

// Define a tip for the Today view
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
    @State private var shouldShowTip = false
    @State private var onboardingCompleted = false
    @Environment(\.colorScheme) private var colorScheme // Add colorScheme
    
    // Initialize the tips
    @State private var navigationTip = NavigationTip()
    @State private var settingsTip = SettingsTip()
    @State private var todayTip = TodayTip()
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                // Add ColorfulX as background
#if !targetEnvironment(macCatalyst)
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
                            .tipKit(todayTip, shouldShowTip: shouldShowTip)
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
                        .tipKit(settingsTip, shouldShowTip: shouldShowTip)
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
            print("Onboarding has been completed, preparing to show tips")
            onboardingCompleted = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task {
                    await invalidateTips()
                    print("Tips have been invalidated, now enabling tips")
                    shouldShowTip = true
                }
            }
        } else {
            print("Onboarding not completed yet")
            shouldShowTip = false
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
        
        // Use consistent view-specific gradients
        switch link {
        case "today":
            // Today view handles its own gradient based on context
            let isWeekend = TodayViewHelpers.isCurrentDateWeekend()
            (gradientManager as GradientManager).updateGradientForContext(
                isAuthenticated: sessionService.isAuthenticated,
                isHolidayMode: Configuration.isHolidayMode,
                isWeekend: isWeekend,
                colorScheme: colorScheme
            )
        case "classtable":
            gradientManager.updateGradientForView(.classtable, colorScheme: colorScheme)
        case "score":
            gradientManager.updateGradientForView(.score, colorScheme: colorScheme)
        case "club-info":
            gradientManager.updateGradientForView(.clubInfo, colorScheme: colorScheme)
        case "club-activity":
            gradientManager.updateGradientForView(.clubActivities, colorScheme: colorScheme)
        case "school-arrangement":
            gradientManager.updateGradientForView(.schoolArrangements, colorScheme: colorScheme)
        case "lunch-menu":
            gradientManager.updateGradientForView(.lunchMenu, colorScheme: colorScheme)
        case "map":
            gradientManager.updateGradientForView(.map, colorScheme: colorScheme)
        default:
            gradientManager.updateGradientForView(.today, colorScheme: colorScheme)
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
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
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
