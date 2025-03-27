import SwiftUI
import ColorfulX

struct ClasstableView: View {
    @StateObject private var viewModel = ClasstableViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var animateIn = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var orientation = UIDevice.current.orientation // Track device orientation
    @EnvironmentObject private var sessionService: SessionService
    @EnvironmentObject private var gradientManager: GradientManager // Add gradient manager

    // Dictionary to map subject keywords to consistent colors
    private let subjectColors: [Color: [String]] = [
        .blue.opacity(0.8): ["Math", "Mathematics", "Maths"],
        .green.opacity(0.8): ["English", "Language", "Literature", "General Paper", "ESL"],
        .orange.opacity(0.8): ["Physics", "Science"],
        .purple.opacity(0.8): ["Chemistry", "Chem"],
        .teal.opacity(0.8): ["Biology", "Bio"],
        .mint.opacity(0.8): ["Further Math", "Maths Further"],
        .yellow.opacity(0.8): ["体育", "PE", "Sports", "P.E"],
        .brown.opacity(0.8): ["Economics", "Econ"],
        .cyan.opacity(0.8): ["Arts", "Art", "TOK"],
        .indigo.opacity(0.8): ["Chinese", "Mandarin", "语文"],
        .gray.opacity(0.8): ["History", "历史", "Geography", "Geo", "政治"]
    ]

    // Function to get subject color from name, used by both this view and others
    static func getSubjectColor(from subjectName: String) -> Color {
        let colors: [Color: [String]] = [
            .blue.opacity(0.8): ["Math", "Mathematics", "Maths"],
            .green.opacity(0.8): ["English", "Language", "Literature", "General Paper", "ESL"],
            .orange.opacity(0.8): ["Physics", "Science"],
            .purple.opacity(0.8): ["Chemistry", "Chem"],
            .teal.opacity(0.8): ["Biology", "Bio"],
            .mint.opacity(0.8): ["Further Math", "Maths Further"],
            .yellow.opacity(0.8): ["体育", "PE", "Sports", "P.E"],
            .brown.opacity(0.8): ["Economics", "Econ"],
            .cyan.opacity(0.8): ["Arts", "Art", "TOK"],
            .indigo.opacity(0.8): ["Chinese", "Mandarin", "语文"],
            .gray.opacity(0.8): ["History", "历史", "Geography", "Geo", "政治"]
        ]

        let subject = subjectName.lowercased()

        // First, try to match the exact or longer phrases to avoid "Math" matching before "Maths Further"
        // Sort keywords by length (longest first) to prioritize more specific matches
        let allKeywords = colors.flatMap { color, keywords in
            keywords.map { (color, $0) }
        }.sorted { $0.1.count > $1.1.count }

        for (color, keyword) in allKeywords {
            if subject.contains(keyword.lowercased()) {
                return color
            }
        }

        // Default color based on subject hash for consistency
        let hash = abs(subject.hashValue)
        let hue = Double(hash % 12) / 12.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }

    // Add periods data based on the provided times (unchanged)
    private var classPeriods: [ClassPeriod] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        return [
            ClassPeriod(number: 1, startTime: calendar.date(bySettingHour: 8, minute: 15, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 8, minute: 55, second: 0, of: today)!),
            ClassPeriod(number: 2, startTime: calendar.date(bySettingHour: 9, minute: 5, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 9, minute: 45, second: 0, of: today)!),
            ClassPeriod(number: 3, startTime: calendar.date(bySettingHour: 9, minute: 55, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 10, minute: 35, second: 0, of: today)!),
            ClassPeriod(number: 4, startTime: calendar.date(bySettingHour: 10, minute: 45, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 11, minute: 25, second: 0, of: today)!),
            ClassPeriod(number: 5, startTime: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 13, minute: 10, second: 0, of: today)!),
            ClassPeriod(number: 6, startTime: calendar.date(bySettingHour: 13, minute: 20, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!),
            ClassPeriod(number: 7, startTime: calendar.date(bySettingHour: 14, minute: 10, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 14, minute: 50, second: 0, of: today)!),
            ClassPeriod(number: 8, startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 15, minute: 40, second: 0, of: today)!),
            ClassPeriod(number: 9, startTime: calendar.date(bySettingHour: 15, minute: 50, second: 0, of: today)!, endTime: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: today)!)
        ]
    }

    // Find the current period or next period (unchanged)
    func getCurrentOrNextPeriod() -> (period: ClassPeriod?, isCurrentlyActive: Bool) {
        let now = Date()
        if let activePeriod = classPeriods.first(where: { $0.isCurrentlyActive() }) {
            return (activePeriod, true)
        }
        let futurePeriods = classPeriods.filter { $0.startTime > now }
        if let nextPeriod = futurePeriods.min(by: { $0.startTime < $1.startTime }) {
            return (nextPeriod, false)
        }
        return (nil, false)
    }

    private var notLoggedInView: some View {
        ContentUnavailableView(
            "Authentication Required",
            systemImage: "person.crop.circle.badge.exclamationmark",
            description: Text("Please sign in to view your classtable.")
        )
        .padding()
    }

    var body: some View {
        ZStack {
            // Add ColorfulX as background with higher opacity
            ColorfulView(
                color: $gradientManager.gradientColors,
                speed: $gradientManager.gradientSpeed,
                noise: $gradientManager.gradientNoise,
                transitionSpeed: $gradientManager.gradientTransitionSpeed
            )
            .ignoresSafeArea()
            .opacity(colorScheme == .dark ? 0.07 : 0.3)

            // Semi-transparent background with reduced opacity for better contrast with gradient
            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if !sessionService.isAuthenticated {
                    notLoggedInView
                } else {
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 0) {
                                // Break up complex expressions to improve type checking
                                let hasNonEmptyTimetable = !viewModel.timetable.isEmpty && viewModel.timetable[0].count > 1

                                // Days of week header - sticky (unchanged)
                                if hasNonEmptyTimetable {
                                    daysHeader
                                        .background(Color(UIColor.tertiarySystemBackground).opacity(0.3))
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                        .zIndex(1)
                                        .overlay(Divider().opacity(0.5), alignment: .bottom)
                                        .padding(.top, 3)
                                        .padding(.bottom, 12)
                                }

                                // Main content depending on loading states (unchanged)
                                if viewModel.years.isEmpty {
                                    if viewModel.isLoadingYears {
                                        TimeTableSkeletonView().padding()
                                    } else {
                                        ContentUnavailableView("No Available Classtable", systemImage: "calendar.badge.exclamationmark")
                                    }
                                } else if viewModel.isLoadingTimetable {
                                    TimeTableSkeletonView().padding()
                                } else if viewModel.timetable.isEmpty {
                                    ContentUnavailableView("No Timetable Data", systemImage: "calendar.badge.exclamationmark", description: Text("No timetable available for the selected year."))
                                } else {
                                    VStack(spacing: 0) {
                                        ForEach(1..<viewModel.timetable.count, id: \.self) { row in
                                            periodRow(row: row)
                                                .padding(.vertical, 4)
                                                .opacity(animateIn ? 1 : 0)
                                                .offset(y: animateIn ? 0 : 20)
                                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(row) * 0.05), value: animateIn)

                                            if row == 4 {
                                                lunchBreakView.padding(.vertical, 12)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 24)
                                    .id(viewModel.selectedYearId)
                                }

                                if let errorMessage = viewModel.errorMessage {
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .padding()
                                        .background(Color(UIColor.systemBackground).opacity(0.8))
                                        .cornerRadius(8)
                                        .padding()
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                        }
//                        .background(Color(UIColor.secondarySystemBackground))
                        .navigationTitle("Classtable")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                // Fixed syntax error: Adding proper block labels
                                if !viewModel.years.isEmpty {
                                    Menu {
                                        ForEach(viewModel.years) { year in
                                            Button(year.W_Year) {
                                                viewModel.selectedYearId = year.W_YearID
                                                viewModel.fetchTimetable()
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    animateIn = false
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                        animateIn = true
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            if let selectedYear = viewModel.years.first(where: { $0.W_YearID == viewModel.selectedYearId }) {
                                                Text(selectedYear.W_Year)
                                                    .foregroundColor(.primary)
                                            } else {
                                                Text("Select Year")
                                                    .foregroundColor(.primary)
                                            }
                                            Image(systemName: "chevron.down")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(UIColor.tertiarySystemBackground).opacity(0.6))
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        )
                                    }
                                } else if viewModel.isLoadingYears {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            }
                        }
                        // Apply rotation for iPhone in portrait mode
                        .rotationEffect(isIphoneInPortrait() ? .degrees(-90) : .degrees(0))
                        .frame(width: isIphoneInPortrait() ? geometry.size.height : geometry.size.width,
                               height: isIphoneInPortrait() ? geometry.size.width : geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchYears()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateIn = true
                }
            }
            // Fixed syntax: adding semicolon between statements
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                orientation = UIDevice.current.orientation
            }
            updateGradientForClasstable()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        }
        .onChange(of: viewModel.isLoadingTimetable) { _, isLoading in
            if !isLoading && !viewModel.timetable.isEmpty {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateIn = true
                }
            }
        }
    }

    // Helper to check if device is iPhone in portrait mode
    private func isIphoneInPortrait() -> Bool {
        let isIphone = UIDevice.current.userInterfaceIdiom == .phone
        let isPortrait = orientation.isPortrait || orientation == .unknown // .unknown assumes portrait as default
        return isIphone && isPortrait
    }

    // Add method to update gradient for classtable
    private func updateGradientForClasstable() {
        gradientManager.updateGradientForView(.classtable, colorScheme: colorScheme)
    }

    // Days of week header (unchanged)
    private var daysHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("")
                .frame(width: 40)
                .font(.caption)
                .padding(.vertical, 12)
            if viewModel.timetable.count > 0 && viewModel.timetable[0].count > 1 {
                ForEach(1..<min(viewModel.timetable[0].count, 6), id: \.self) { col in
                    Text(viewModel.timetable[0][col])
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal)
    }

    // Period row (unchanged)
    private func periodRow(row: Int) -> some View {
        let periods = ClassPeriodsManager.shared.classPeriods
        let currentPeriod = periods.first(where: { $0.number == row && $0.isCurrentlyActive() })

        return ZStack(alignment: .top) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(row)")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 25, height: 25)
                    .padding(.top, 15)
                if row < viewModel.timetable.count {
                    ForEach(1..<min(viewModel.timetable[row].count, 6), id: \.self) { col in
                        ClassCell(cellContent: viewModel.timetable[row][col], colorMap: subjectColors)
                    }
                }
            }
            if let period = currentPeriod {
                HStack(spacing: 8) {
                    Rectangle().fill(Color.clear).frame(width: 25)
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 2)
                        .offset(y: 70 * period.currentProgressPercentage())
                        .animation(.spring(response: 0.3), value: period.currentProgressPercentage())
                }
                .zIndex(2)
            }
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
    }

    // Lunch break view (unchanged)
    private var lunchBreakView: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.3))
            Text("Lunch Break")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Capsule().fill(Color.secondary.opacity(0.1)))
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.3))
        }
        .padding(.horizontal, 24)
        .opacity(animateIn ? 1 : 0)
        .animation(.easeIn.delay(0.3), value: animateIn)
    }
}

// Class cell component that displays teacher, subject, and classroom
struct ClassCell: View {
    let cellContent: String
    let colorMap: [Color: [String]]
    @Environment(\.colorScheme) private var colorScheme

    private var components: [String] {
        cellContent.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
    }

    private var subjectColor: Color {
        // Try to find the subject color based on keywords
        guard components.count > 1 else { return .gray.opacity(0.5) }

        return ClasstableView.getSubjectColor(from: components[1])
    }

    private var hasContent: Bool {
        return components.count > 0 && !cellContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 4) {
                if components.count > 0 {
                    // Teacher name
                    Text(components[0])
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Subject name - highlighted
                    if components.count > 1 {
                        Text(components[1])
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(subjectColor)
                            .cornerRadius(4)
                            .lineLimit(1)
                    }

                    // Classroom
                    if components.count > 2 {
                        Text(components[2])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            // .glassmorphicCard(cornerRadius: 8) // Removed glassmorphic style
            .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.5 : 0.8)) // Add a simple background
            .cornerRadius(8) // Keep the corner radius
            .contentShape(Rectangle())
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .padding(12)
        }
    }
}

// Skeleton loading view for the timetable
struct TimeTableSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            // Day headers
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 30, height: 20)

                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 20)
                        .frame(maxWidth: .infinity)
                }
            }

            // Period rows
            ForEach(0..<8, id: \.self) { _ in
                HStack(spacing: 8) {
                    // Period number
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 30, height: 30)

                    // Class cells
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 70)
                            .frame(maxWidth: .infinity)
                            // .glassmorphicCard(cornerRadius: 8) // Removed glassmorphic style
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    NavigationStack {
        ClasstableView()
    }
}
