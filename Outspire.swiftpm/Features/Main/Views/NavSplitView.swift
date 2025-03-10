import SwiftUI

struct NavSplitView: View {
    @EnvironmentObject var sessionService: SessionService
    @State private var selectedLink: String? = "today"
    @State private var showSettingsSheet = false
    @State private var refreshID = UUID()
    
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
                        Label("Academic Score", systemImage: "pencil.and.list.clipboard")
                    }
                }
                
                Section {
                    NavigationLink(value: "club-info") {
                        Label("Club List", systemImage: "person.2.circle")
                    }
                    NavigationLink(value: "club-activity") {
                        Label("CAS Activities", systemImage: "checklist")
                    }
                    NavigationLink(value: "school-arrangement") {
                        Label("School Arrangement", systemImage: "calendar.badge.clock")
                    }
                } header: {
                    Text("Activities")
                }
                NavigationLink(value: "help") {
                    Label("Help", systemImage: "questionmark.circle.dashed")
                }
            }
            .toolbar {
                Button(action: {
                    showSettingsSheet.toggle()
                }, label: {
                    Image(systemName: "gear")
                })
            }
            .navigationTitle("Outspire")
            .contentMargins(.vertical, 10)
            .sheet(isPresented: $showSettingsSheet, content: {
                SettingsView(showSettingsSheet: $showSettingsSheet)
                    .onDisappear { // Refresh when the settings sheet is dismissed
                        refreshID = UUID()
                    }
            })
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
            case .some("help"):
                HelpView()
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
    }
}
