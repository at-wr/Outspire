import SwiftUI
import TipKit

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
    @EnvironmentObject var settingsManager: SettingsManager // Add environment object
    @State private var selectedLink: String? = "today"
    // Remove the local showSettingsSheet state and use the one from settingsManager
    @State private var refreshID = UUID()
    @State private var showOnboardingSheet = false
    @State private var hasCheckedOnboarding = false
    @AppStorage("lastVersionRun") private var lastVersionRun: String?
    @State private var shouldShowTip = false
    @State private var onboardingCompleted = false
    
    // Initialize the tips
    @State private var navigationTip = NavigationTip()
    @State private var settingsTip = SettingsTip()
    @State private var todayTip = TodayTip()
    
    var body: some View {
        NavigationSplitView {
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
#if targetEnvironment(macCatalyst)
            .navigationSplitViewColumnWidth(min: 100, ideal: 200, max: 300)
#endif
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
        } detail: {
            detailView
        }
        .onChange(of: Configuration.hideAcademicScore) { newValue in
            if newValue && selectedLink == "score" {
                selectedLink = "today"
            }
            refreshID = UUID()
        }
        .id(refreshID)
        .task {
            await configureTipsAndCheckOnboarding()
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
