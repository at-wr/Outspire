import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var urlSchemeHandler: URLSchemeHandler
    @EnvironmentObject var gradientManager: GradientManager

    @ObservedObject private var authV2 = AuthServiceV2.shared

    @State private var selectedTab: MainTab = .today

    enum MainTab: Hashable { case today, classtable, activities, search }

    var body: some View {
        if authV2.isResolvingSession {
            ProgressView()
        } else if #available(iOS 26.0, *) {
            ios26TabView
        } else if #available(iOS 18.0, *) {
            ios18TabView
        } else {
            legacyTabView
        }
    }

    // MARK: - iOS 26+ (Liquid Glass tab bar)

    @available(iOS 26.0, *)
    private var ios26TabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "text.rectangle.page.fill", value: MainTab.today) {
                NavigationStack {
                    TodayView()
                }
            }

            Tab("Class", systemImage: "calendar.day.timeline.left", value: MainTab.classtable) {
                NavigationStack {
                    ModernClasstableView()
                }
            }

            Tab("Activities", systemImage: "checklist.checked", value: MainTab.activities) {
                NavigationStack {
                    ClubActivitiesView()
                }
            }

            Tab("Explore", systemImage: "square.grid.2x2", value: MainTab.search) {
                NavigationStack {
                    ExtraView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    // MARK: - iOS 18+

    @available(iOS 18.0, *)
    private var ios18TabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "text.rectangle.page.fill", value: MainTab.today) {
                NavigationStack {
                    TodayView()
                }
            }

            Tab("Class", systemImage: "calendar.day.timeline.left", value: MainTab.classtable) {
                NavigationStack {
                    ModernClasstableView()
                }
            }

            Tab("Activities", systemImage: "checklist.checked", value: MainTab.activities) {
                NavigationStack {
                    ClubActivitiesView()
                }
            }

            Tab("Explore", systemImage: "square.grid.2x2", value: MainTab.search) {
                NavigationStack {
                    ExtraView()
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    // MARK: - Legacy

    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "text.rectangle.page.fill") }
            .tag(MainTab.today)

            NavigationStack {
                ModernClasstableView()
            }
            .tabItem { Label("Class", systemImage: "calendar.day.timeline.left") }
            .tag(MainTab.classtable)

            NavigationStack {
                ClubActivitiesView()
            }
            .tabItem { Label("Activities", systemImage: "checklist.checked") }
            .tag(MainTab.activities)

            NavigationStack {
                ExtraView()
            }
            .tabItem { Label("Explore", systemImage: "square.grid.2x2") }
            .tag(MainTab.search)
        }
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.playSelectionFeedback()
        }
    }
}
