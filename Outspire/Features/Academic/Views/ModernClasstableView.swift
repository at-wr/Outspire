import SwiftUI

struct ModernClasstableView: View {
    @StateObject private var viewModel = ClasstableViewModel()
    @State private var selectedDay: Int = ModernClasstableView.currentWeekdayIndex()

    static func currentWeekdayIndex() -> Int {
        let w = Calendar.current.component(.weekday, from: Date())
        // Monday=2..Friday=6 -> 0..4; weekend clamp to 0
        return (w == 1 || w == 7) ? 0 : max(0, min(4, w - 2))
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Day", selection: $selectedDay) {
                Text("Mon").tag(0)
                Text("Tue").tag(1)
                Text("Wed").tag(2)
                Text("Thu").tag(3)
                Text("Fri").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                ForEach(ClassPeriodsManager.shared.classPeriods, id: \.number) { period in
                    if let info = classInfo(for: period, dayIndex: selectedDay) {
                        ModernScheduleRow(period: period, info: info)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDetail = ClassDetail(period: period, info: info)
                                isShowingDetail = true
                            }
                    } else {
                        ModernScheduleRow(period: period, info: ClassInfo(teacher: nil, subject: nil, room: nil, isSelfStudy: true))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.automatic)
        }
        .navigationTitle("Class")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Today") { selectedDay = Self.currentWeekdayIndex() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.refreshData()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.years.isEmpty {
                    Menu {
                        ForEach(viewModel.years) { year in
                            Button(year.W_Year) { viewModel.selectYear(year.W_YearID) }
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
        }
        .task {
            if viewModel.years.isEmpty { viewModel.fetchYears() }
            if viewModel.timetable.isEmpty { viewModel.fetchTimetable() }
        }
        .sheet(item: $selectedDetail) { detail in
            NavigationStack {
                ClassDetailSheet(period: detail.period, info: detail.info)
                    .navigationTitle(detail.info.subject ?? (detail.info.isSelfStudy ? "Self-Study" : "Class"))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func classInfo(for period: ClassPeriod, dayIndex: Int) -> ClassInfo? {
        guard !viewModel.timetable.isEmpty,
              period.number < viewModel.timetable.count,
              dayIndex + 1 < viewModel.timetable[period.number].count else { return nil }
        let data = viewModel.timetable[period.number][dayIndex + 1]
        let info = ClassInfoParser.parse(data)
        return info.isSelfStudy && (info.subject == nil) ? nil : info
    }
    struct ClassDetail: Identifiable { let id = UUID(); let period: ClassPeriod; let info: ClassInfo }
    @State private var selectedDetail: ClassDetail?
    @State private var isShowingDetail: Bool = false
}

private struct ModernScheduleRow: View {
    let period: ClassPeriod
    let info: ClassInfo

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("\(period.number)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(subjectColor)
                .frame(width: 44, alignment: .center)

            VStack(alignment: .leading, spacing: 6) {
                Text(info.subject ?? (info.isSelfStudy ? "Self-Study" : "Class"))
                    .font(.body.weight(.semibold))
                Text(period.timeRangeFormatted)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var subjectColor: Color {
        if let subject = info.subject { return ClasstableView.getSubjectColor(from: subject) }
        return .primary
    }
}

private struct ClassDetailSheet: View {
    let period: ClassPeriod
    let info: ClassInfo

    var body: some View {
        List {
            Text(info.subject ?? (info.isSelfStudy ? "Self-Study" : "Class"))
                .font(.title2)
                .padding(.vertical, 2)

            if let teacher = info.teacher, !teacher.isEmpty {
                Label(teacher, systemImage: "person")
            }
            if let room = info.room, !room.isEmpty {
                Label(room, systemImage: "mappin.circle")
            }

            Label(period.timeRangeFormatted, systemImage: "clock")
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Details")
    }
}
