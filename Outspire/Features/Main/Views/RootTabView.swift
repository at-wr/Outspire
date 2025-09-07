import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var urlSchemeHandler: URLSchemeHandler
    @EnvironmentObject var gradientManager: GradientManager

    @State private var selectedTab: MainTab = .today

    enum MainTab: Hashable { case today, classtable, activities, search }

    var body: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Today", systemImage: "text.rectangle.page", value: MainTab.today) {
                    NavigationStack {
                        TodayView()
                    }
                }

                Tab("Class", systemImage: "calendar.day.timeline.left", value: MainTab.classtable) {
                    NavigationStack {
                        ModernClasstableView()
                    }
                }

                Tab("Activities", systemImage: "checklist", value: MainTab.activities) {
                    NavigationStack {
                        ClubActivitiesView()
                    }
                }

                Tab("Search", systemImage: "magnifyingglass", value: MainTab.search, role: .search) {
                    NavigationStack {
                        ExtraView()
                    }
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    TodayView()
                }
                .tabItem { Label("Today", systemImage: "text.rectangle.page") }
                .tag(MainTab.today)

                NavigationStack {
                    ModernClasstableView()
                }
                .tabItem { Label("Class", systemImage: "calendar.day.timeline.left") }
                .tag(MainTab.classtable)

                NavigationStack {
                    ClubActivitiesView()
                }
                .tabItem { Label("Activities", systemImage: "checklist") }
                .tag(MainTab.activities)

                NavigationStack {
                    ExtraView()
                }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(MainTab.search)
            }
        }
    }
}
