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

struct NavSplitView: View {
    @EnvironmentObject var sessionService: SessionService
    @State private var selectedLink: String? = "today"
    @State private var showSettingsSheet = false
    @State private var showOnboardingSheet = false
    @State private var refreshID = UUID()
    @State private var hasCheckedOnboarding = false  // Add this line
    
    // Initialize the tip properly
    private let navigationTip = NavigationTip()
    
    var body: some View {
        NavigationSplitView {
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
                        Label("School Arrangement", systemImage: "calendar.badge.clock")
                    }
                    NavigationLink(value: "lunch-menu") {
                        Label("Dining Information", systemImage: "fork.knife")
                    }
                    NavigationLink(value: "help") {
                        Label("Help", systemImage: "questionmark.circle.dashed")
                    }
                } header: {
                    Text("Miscellaneous")
                }
            }
            .toolbar {
                Button(action: {
                    showSettingsSheet.toggle()
                }, label: {
                    Image(systemName: "gear")
                })
                //.popoverTip(navigationTip)
            }
            .navigationTitle("Outspire")
            .contentMargins(.vertical, 10)
            .sheet(isPresented: $showSettingsSheet, content: {
                SettingsView(showSettingsSheet: $showSettingsSheet)
                    .onDisappear { // Refresh when the settings sheet is dismissed
                        refreshID = UUID()
                    }
            })
            .sheet(isPresented: $showOnboardingSheet) {
                OnboardingView(isPresented: $showOnboardingSheet)
            }
        } detail: {
            switch selectedLink {
            case .some("today"):
                TodayView()
            case .some("classtable"):
                ClasstableView()
            case .some("score"):
                ScoreView()
            case .some("club-info"):
                ClubInfoView()
            case .some("club-activity"):
                ClubActivitiesView()
            case .some("school-arrangement"):
                SchoolArrangementView()
            case .some("lunch-menu"):
                LunchMenuView()
            case .some("help"):
                HelpView()
            case .some("map"):
                MapView()
            default:
                TodayView()
            }
        }
        .onChange(of: Configuration.hideAcademicScore) { newValue in
            // If we're hiding Academic Score and it's currently selected, change to default
            if newValue && selectedLink == "score" {
                selectedLink = "today"
            }
            refreshID = UUID() // Also refresh on this change.
        }
        .id(refreshID) // Force refresh of the entire view
        .task {
            // Configure TipKit on app launch
            try? Tips.configure([
                .displayFrequency(.immediate)
            ])
            
            // Check if onboarding should be shown
            if !hasCheckedOnboarding {
                hasCheckedOnboarding = true
                
                // Short delay to ensure view is fully loaded before showing sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                        showOnboardingSheet = true
                    }
                }
            }
        }
    }
}
