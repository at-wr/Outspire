import SwiftUI

struct ExtraView: View {
    @State private var query: String = ""
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        List {
            Section("Explore") {
                NavigationLink(destination: SchoolArrangementView()) {
                    Label("School Arrangements", systemImage: "calendar.badge.clock")
                }
                NavigationLink(destination: LunchMenuView()) {
                    Label("Dining Menus", systemImage: "fork.knife")
                }
                NavigationLink(destination: ScoreView()) {
                    Label("Academic Grades", systemImage: "pencil.and.list.clipboard")
                }
                NavigationLink(destination: ClubInfoView()) {
                    Label("Hall of Clubs", systemImage: "person.2.circle")
                }
                NavigationLink(destination: ReflectionsView()) {
                    Label("Reflections", systemImage: "square.and.pencil")
                }
                NavigationLink(destination: SettingsView(showSettingsSheet: .constant(false), isModal: false)) {
                    Label("Settings", systemImage: "gear")
                }
                NavigationLink(destination: TodayView()) {
                    Label("Today", systemImage: "text.rectangle.page")
                }
                NavigationLink(destination: ClasstableView()) {
                    Label("Class Schedule", systemImage: "calendar.day.timeline.left")
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Search")
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var headerHero: some View {
        EmptyView()
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title).font(AppText.title)
    }
}

private struct RowLink: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        Label(title, systemImage: icon)
    }
}
