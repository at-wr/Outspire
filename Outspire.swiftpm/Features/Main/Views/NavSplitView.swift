import SwiftUI

struct NavSplitView: View {
    @EnvironmentObject var sessionService: SessionService
    @State private var selectedLink: String? = "today"
    @State private var showSettingsSheet = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedLink) {
                NavigationLink(value: "today") {
                    Label("Today", systemImage: "text.rectangle.page")
                }
                NavigationLink(value: "classtable") {
                    Label("Classtable", systemImage:  "clock.badge.questionmark")
                }
                NavigationLink(value: "score") {
                    Label("Acedamic Score", systemImage:  "pencil.and.list.clipboard")
                }
                
                Section {
                    NavigationLink(value: "club-info") {
                        Label("Club List", systemImage: "person.2.circle")
                    }
                    NavigationLink(value: "club-activity") {
                        Label("CAS Activities", systemImage:  "checklist")
                    }
                } header: {
                    Text("Activities")
                }
                NavigationLink(value: "help") {
                    Label("Help", systemImage: "questionmark.circle.dashed")
                }
            }
            .toolbar {
                Button (action: {
                    showSettingsSheet.toggle()
                }, label: {
                    Image(systemName: "gear")
                })
            }
            .navigationTitle("Outspire")
            .contentMargins(.vertical, 10)
            .sheet(isPresented: $showSettingsSheet, content: {
                SettingsView(showSettingsSheet: $showSettingsSheet)
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
            case .some("help"):
                HelpView()
            default:
                TodayView()
            }
        }
    }
}
