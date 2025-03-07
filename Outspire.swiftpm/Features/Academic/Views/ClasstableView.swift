import SwiftUI

// Add this structure to store period time information
struct ClassPeriod {
    let number: Int
    let startTime: Date
    let endTime: Date
    
    // Helper to check if current time is within this period
    func isCurrentlyActive() -> Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
    
    // Calculate percentage of period completed (for indicator positioning)
    func currentProgressPercentage() -> CGFloat {
        let now = Date()
        if now < startTime { return 0 }
        if now > endTime { return 1 }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsedDuration = now.timeIntervalSince(startTime)
        return CGFloat(elapsedDuration / totalDuration)
    }
}

struct ClasstableView: View {
    @StateObject private var viewModel = ClasstableViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var animateIn = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    // Dictionary to map subjects to consistent colors
    private let subjectColors: [String: Color] = [
        "Math": .blue.opacity(0.8),
        "English": .green.opacity(0.8),
        "Physics": .orange.opacity(0.8),
        "Chemistry": .purple.opacity(0.8),
        "Biology": .pink.opacity(0.8),
        "CS": .mint.opacity(0.8),
        "PE": .red.opacity(0.8),
        "History": .brown.opacity(0.8),
        "Geography": .cyan.opacity(0.8),
        "Chinese": .indigo.opacity(0.8)
    ]
    
    // Add periods data based on the provided times
    private var classPeriods: [ClassPeriod] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return [
            ClassPeriod(
                number: 1,
                startTime: calendar.date(bySettingHour: 8, minute: 15, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 8, minute: 55, second: 0, of: today)!
            ),
            ClassPeriod(
                number: 2,
                startTime: calendar.date(bySettingHour: 9, minute: 5, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 9, minute: 45, second: 0, of: today)!
            ),
            ClassPeriod(
                number: 3,
                startTime: calendar.date(bySettingHour: 9, minute: 55, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 10, minute: 35, second: 0, of: today)!
            ),
            ClassPeriod(
                number: 4,
                startTime: calendar.date(bySettingHour: 10, minute: 45, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 11, minute: 25, second: 0, of: today)!
            ),
            ClassPeriod(
                number: 5,
                startTime: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 13, minute: 10, second: 0, of: today)!
            ),
            ClassPeriod(
                number: 6,
                startTime: calendar.date(bySettingHour: 13, minute: 20, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!
            ),
            ClassPeriod(
                number: 7,
                startTime: calendar.date(bySettingHour: 14, minute: 10, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 14, minute: 50, second: 0, of: today)!
            ),
            ClassPeriod(
                number: 8,
                startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 15, minute: 40, second: 0, of: today)!
            ),
            ClassPeriod(
                number: 9,
                startTime: calendar.date(bySettingHour: 15, minute: 50, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: today)!
            )
        ]
    }
    
    // Find the current period or next period
    func getCurrentOrNextPeriod() -> (period: ClassPeriod?, isCurrentlyActive: Bool) {
        let now = Date()
        
        // Check if we're currently in a period
        if let activePeriod = classPeriods.first(where: { $0.isCurrentlyActive() }) {
            return (activePeriod, true)
        }
        
        // Find next period
        let futurePeriods = classPeriods.filter { $0.startTime > now }
        if let nextPeriod = futurePeriods.min(by: { $0.startTime < $1.startTime }) {
            return (nextPeriod, false)
        }
        
        return (nil, false)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Days of week header - sticky
                if !viewModel.timetable.isEmpty && viewModel.timetable[0].count > 1 {
                    daysHeader
                        .background(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        .zIndex(1) // Ensure header appears above the content
                        .overlay(
                            Divider().opacity(0.5), alignment: .bottom
                        )
                        .padding(.top, 3) // Small padding to show shadow
                        .padding(.bottom, 12)
                }
                
                // Main content depending on loading states
                if viewModel.years.isEmpty {
                    if viewModel.isLoadingYears {
                        TimeTableSkeletonView()
                            .padding()
                    } else {
                        ContentUnavailableView("No Available Classtable", systemImage: "calendar.badge.exclamationmark")
                    }
                } else if viewModel.isLoadingTimetable {
                    TimeTableSkeletonView()
                        .padding()
                } else if viewModel.timetable.isEmpty {
                    ContentUnavailableView("No Timetable Data", systemImage: "calendar.badge.exclamationmark", description: Text("No timetable available for the selected year."))
                } else {
                    // Periods and classes
                    VStack(spacing: 0) {
                        ForEach(1..<viewModel.timetable.count, id: \.self) { row in
                            periodRow(row: row)
                                .padding(.vertical, 4)
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(row) * 0.05),
                                    value: animateIn
                                )
                            
                            if row == 4 {
                                lunchBreakView
                                    .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                    // Use ID to ensure view is recreated properly on data refresh
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
        .background(Color(UIColor.secondarySystemBackground))
        .navigationTitle("Classtable")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.years.isEmpty {
                    Menu {
                        ForEach(viewModel.years) { year in
                            Button(year.W_Year) {
                                viewModel.selectedYearId = year.W_YearID
                                viewModel.fetchTimetable()
                                
                                // Only animate the content, not the whole view
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
                                .fill(Color(UIColor.tertiarySystemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                    .disabled(viewModel.isLoadingYears)
                    .opacity(viewModel.isLoadingYears ? 0.6 : 1.0)
                } else if viewModel.isLoadingYears {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        // Add timer to update the time indicator
        .onAppear {
            viewModel.fetchYears()
            
            // Animate content in when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateIn = true
                }
            }
            
            // Create a timer to update current time every minute
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: viewModel.isLoadingTimetable) { isLoading in
            // Properly handle animation transitions after loading completes
            if !isLoading && !viewModel.timetable.isEmpty {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateIn = true
                }
            }
        }
    }
    
    // Days of week header (Mon, Tue, Wed, etc)
    private var daysHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("") // Period number column
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
    
    // Modified periodRow function to include time indicator
    private func periodRow(row: Int) -> some View {
        let periods = ClassPeriodsManager.shared.classPeriods
        let currentPeriod = periods.first(where: { $0.number == row && $0.isCurrentlyActive() })
        
        return ZStack(alignment: .top) {
            // Regular period row content
            HStack(alignment: .top, spacing: 8) {
                // Period number
                Text("\(row)")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 25, height: 25)
                    .padding(.top, 15)
                
                // Classes for each day
                if row < viewModel.timetable.count {
                    ForEach(1..<min(viewModel.timetable[row].count, 6), id: \.self) { col in
                        ClassCell(cellContent: viewModel.timetable[row][col], colorMap: subjectColors)
                    }
                }
            }
            
            // Time indicator overlay if this is the current period
            if let period = currentPeriod {
                HStack(spacing: 8) {
                    // Space for period number
                    Rectangle().fill(Color.clear).frame(width: 25)
                    
                    // Time indicator line across all cells
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 2)
                        .offset(y: 70 * period.currentProgressPercentage())
                        .animation(.spring(response: 0.3), value: period.currentProgressPercentage())
                }
            }
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
    
    // Lunch break divider
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
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                )
            
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
    let colorMap: [String: Color]
    @Environment(\.colorScheme) private var colorScheme
    
    private var components: [String] {
        cellContent.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
    }
    
    private var subjectColor: Color {
        // Try to find the subject color based on keywords
        guard components.count > 1 else { return .gray.opacity(0.5) }
        
        let subjectName = components[1].lowercased()
        
        for (keyword, color) in colorMap {
            if subjectName.contains(keyword.lowercased()) {
                return color
            }
        }
        
        // Hash-based color for consistent colors per subject
        let hash = abs(subjectName.hashValue)
        let hue = Double(hash % 12) / 12.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }
    
    private var hasContent: Bool {
        return components.count > 0 && !cellContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 4) {
                if components.count > 0 {
                    // Teacher name
                    if components.count > 0 {
                        Text(components[0])
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
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
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.tertiarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            )
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
