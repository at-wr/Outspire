import SwiftUI
import CoreLocation

// Create a reusable card background modifier for consistent style
struct GlassmorphicCard: ViewModifier {
    var isDimmed: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base blur layer
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(colorScheme == .dark ? 0.8 : 0.92)
                    
                    // Subtle gradient overlay for depth
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.3),
                                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(isDimmed ? 0.5 : 1.0)
                    
                    // Very subtle border - matched to EnhancedClassCard
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.5),
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                        .opacity(isDimmed ? 0.5 : 1.0)
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.08),
                    radius: 15,
                    x: 0,
                    y: 5
                )
            )
            .opacity(isDimmed ? 0.85 : 1.0)
    }
}

// Extension to apply the modifier easily
extension View {
    func glassmorphicCard(isDimmed: Bool = false) -> some View {
        self.modifier(GlassmorphicCard(isDimmed: isDimmed))
    }
}

// No upcoming class card
struct NoClassCard: View {
    let isDimmed: Bool
    
    init(isDimmed: Bool = false) {
        self.isDimmed = isDimmed
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.1))
                )
            
            VStack(spacing: 5) {
                Text("No Classes Scheduled Today")
                    .font(.headline)
                
                Text("Enjoy your free time!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .paddedGlassmorphicCard(horizontalPadding: 0, verticalPadding: 0)
    }
}

// Weekend card
struct WeekendCard: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.yellow.opacity(0.1))
                )
            
            VStack(spacing: 5) {
                Text("It's the Weekend!")
                    .font(.headline)
                
                Text("Relax and have a great weekend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .paddedGlassmorphicCard(horizontalPadding: 0, verticalPadding: 0)
    }
}

// Holiday mode card
struct HolidayModeCard: View {
    let hasEndDate: Bool
    let endDate: Date
    
    private var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: endDate)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                )
            
            VStack(spacing: 5) {
                Text("Holiday Mode")
                    .font(.headline)
                
                Text("Enjoy your time off from classes!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if hasEndDate {
                    Text("Until \(formattedEndDate)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .paddedGlassmorphicCard(horizontalPadding: 0, verticalPadding: 0)
    }
}

// School information card
struct SchoolInfoCard: View {
    let assemblyTime: String
    let arrivalTime: String
    let travelInfo: (travelTime: TimeInterval?, distance: CLLocationDistance?)?
    let isInChina: Bool
    let isReturningFromSheet: Bool
    
    @State private var isTravelInfoVisible: Bool = false
    
    init(
        assemblyTime: String,
        arrivalTime: String,
        travelInfo: (travelTime: TimeInterval?, distance: CLLocationDistance?)?,
        isInChina: Bool,
        isReturningFromSheet: Bool = false
    ) {
        self.assemblyTime = assemblyTime
        self.arrivalTime = arrivalTime
        self.travelInfo = travelInfo
        self.isInChina = isInChina
        self.isReturningFromSheet = isReturningFromSheet
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Information", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let travelInfo = travelInfo, 
                   let travelTime = travelInfo.travelTime, 
                   let distance = travelInfo.distance {
                    
                    // Use the ID to force view recreation when data changes significantly
                    let significantChange = Int(travelTime/60) // Minutes value for ID
                    
                    TravelTimeInfoView(
                        travelTime: travelTime,
                        distance: distance
                    )
                    .id("travel-\(significantChange)")
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            
            Divider()
            
            VStack(spacing: 12) {
                InfoRow(icon: "door.left.hand.open", title: "Arrival Time", value: arrivalTime, color: .purple)
                InfoRow(icon: "bell.fill", title: "Morning Assembly", value: assemblyTime, color: .blue)
                InfoRow(icon: "fork.knife", title: "Lunch Break", value: "11:30 - 12:30", color: .orange)
                InfoRow(icon: "figure.walk", title: "After School Activities", value: "16:30 - 18:00", color: .green)
            }
        }
        .padding(16)
        .paddedGlassmorphicCard(horizontalPadding: 0, verticalPadding: 0)
        .onAppear {
            // Delay showing travel info to ensure smooth card animation
            withAnimation(.easeIn.delay(0.3)) {
                isTravelInfoVisible = true
            }
        }
    }
}

// Daily schedule summary card
struct DailyScheduleCard: View {
    @ObservedObject var viewModel: ClasstableViewModel
    let dayIndex: Int
    let maxClassesToShow: Int = 3
    @State private var isExpandedSchedule = false
    @State private var isClassesOver: Bool = false
    
    // Convert dayIndex (0-4) to weekday (2-6, Monday-Friday)
    private var dayWeekday: Int { dayIndex + 2 }
    
    // Class period model that conforms to Equatable and Identifiable
    struct ClassPeriodItem: Equatable, Identifiable {
        let id: String  // Using composite id for uniqueness
        let period: Int
        let data: String
        let isSelfStudy: Bool
        
        init(period: Int, data: String, isSelfStudy: Bool) {
            self.id = "\(period)-\(isSelfStudy ? "self" : "class")"
            self.period = period
            self.data = data
            self.isSelfStudy = isSelfStudy
        }
        
        static func == (lhs: ClassPeriodItem, rhs: ClassPeriodItem) -> Bool {
            return lhs.period == rhs.period &&
            lhs.data == rhs.data &&
            lhs.isSelfStudy == rhs.isSelfStudy
        }
    }
    
    // Get max periods for this day of the week
    private var maxPeriodsForDay: Int {
        ClassPeriodsManager.shared.getMaxPeriodsByWeekday(dayWeekday)
    }
    
    // Check if there are any classes or self-study periods for the day
    private var hasClasses: Bool {
        guard !viewModel.timetable.isEmpty, viewModel.timetable.count > 1 else { return false }
        return (1..<min(viewModel.timetable.count, maxPeriodsForDay + 1)).contains { row in
            row < viewModel.timetable.count && dayIndex + 1 < viewModel.timetable[row].count
        }
    }
    
    // Get a list of classes/self-study periods for the day using our new struct
    private var scheduledClassesForToday: [ClassPeriodItem] {
        guard !viewModel.timetable.isEmpty else { return [] }
        
        let maxRow = min(viewModel.timetable.count, maxPeriodsForDay + 1)
        return (1..<maxRow).compactMap { row in
            guard row < viewModel.timetable.count && dayIndex + 1 < viewModel.timetable[row].count else {
                return nil
            }
            
            let classData = viewModel.timetable[row][dayIndex + 1]
            let isSelfStudy = classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            return ClassPeriodItem(
                period: row,
                data: isSelfStudy ? "Class-Free\n\nSelf-Study" : classData,
                isSelfStudy: isSelfStudy
            )
        }
    }
    
    // Add method to check if all classes for today are over
    private func checkIfClassesOver() {
        let now = Date()
        // Check if it's a weekday
        if dayIndex >= 0 && dayIndex <= 4 {
            // Get all classes for today
            let classes = scheduledClassesForToday
            if !classes.isEmpty {
                // Find the last class period
                if let lastClassPeriod = classes.map({ $0.period }).max(),
                   let lastPeriod = ClassPeriodsManager.shared.classPeriods.first(where: { $0.number == lastClassPeriod }) {
                    // Check if current time is past the end time of the last class
                    isClassesOver = now > lastPeriod.endTime
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card header with class count
            HStack {
                Label("Schedule", systemImage: "calendar.day.timeline.left")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if hasClasses {
                    let regularClassCount = scheduledClassesForToday.filter { !$0.isSelfStudy }.count
                    let selfStudyCount = scheduledClassesForToday.filter { $0.isSelfStudy }.count
                    
                    Text("\(regularClassCount) Classes, \(selfStudyCount) Self-Study")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            Divider()
            
            // Class listing
            if hasClasses {
                VStack(spacing: 12) {
                    // Only show periods up to maxClassesToShow or all if expanded
                    let visibleClasses = isExpandedSchedule ? 
                    scheduledClassesForToday : 
                    Array(scheduledClassesForToday.prefix(maxClassesToShow))
                    
                    ForEach(visibleClasses) { item in
                        if let period = ClassPeriodsManager.shared.classPeriods.first(where: { $0.number == item.period }) {
                            // Get components - handle both regular classes and self-study
                            let components = item.data
                                .replacingOccurrences(of: "<br>", with: "\n")
                                .components(separatedBy: "\n")
                                .filter { !$0.isEmpty }
                            
                            if !components.isEmpty {
                                ScheduleRow(
                                    period: item.period,
                                    time: period.timeRangeFormatted,
                                    subject: components.count > 1 ? components[1] : "Class",
                                    room: components.count > 2 ? components[2] : "",
                                    isSelfStudy: item.isSelfStudy
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    
                    // Only show expand button if there are more classes than default view
                    if scheduledClassesForToday.count > maxClassesToShow {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpandedSchedule.toggle()
                            }
                        } label: {
                            HStack {
                                Text(isExpandedSchedule ? "See Less" : "See Full Schedule")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .rotationEffect(.degrees(isExpandedSchedule ? 180 : 0))
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Color.blue)
                        }
                        .padding(.top, 6)
                    }
                }
            } else {
                Text("No classes scheduled for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .paddedGlassmorphicCard(isDimmed: isClassesOver, horizontalPadding: 0, verticalPadding: 0)
        .animation(.easeInOut(duration: 0.3), value: scheduledClassesForToday)
        .animation(.easeInOut(duration: 0.5), value: isClassesOver)
        .onAppear {
            checkIfClassesOver()
        }
        .onChange(of: dayIndex) { _ in
            checkIfClassesOver()
        }
    }
}

// Sign in prompt card
struct SignInPromptCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            
            Image(systemName: "party.popper.fill")
                .font(.system(size: 60))
                .foregroundStyle(.cyan.opacity(0.8))
                .padding(.bottom, 10)
            
            Text("Welcome to Outspire!")
                .font(.title)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
            
            Text("Make your campus life easier")
                .font(.title3)
                .foregroundStyle(.secondary)
//                .fontWeight(.bold)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            // Sign-in button
            Button(action: {
                settingsManager.showSettingsSheet = true
            }) {
                HStack {
                    Image(systemName: "person.fill.viewfinder")
                    Text("Sign In with TSIMS")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            }
            .padding(.top, 10)
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .padding()
    }
}

// Add the button style that was in TodayView
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Self Study Period Card - Optimized
struct SelfStudyPeriodCard: View {
    let currentPeriod: Int
    let nextClassPeriod: Int?
    let nextClassName: String?
    let dayOfWeek: Int? // 1-7, where 1 is Sunday
    
    private var isLastPeriodOfDay: Bool {
        guard let dayOfWeek = dayOfWeek else { return false }
        return currentPeriod >= ClassPeriodsManager.shared.getMaxPeriodsByWeekday(dayOfWeek)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.fill")
                .font(.system(size: 40))
                .foregroundStyle(.purple)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                )
            
            VStack(spacing: 5) {
                Text("Self-Study Period")
                    .font(.headline)
                
                Text("Period \(currentPeriod)\(isLastPeriodOfDay ? " (Last Period)" : "")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let nextClassPeriod = nextClassPeriod, let nextClassName = nextClassName {
                    Text("Next class: Period \(nextClassPeriod) - \(nextClassName)")
                        .font(.caption)
                        .foregroundStyle(.purple)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .glassmorphicCard()
    }
}

// Self Study
struct LunchBreakCard: View {
    let nextClassPeriod: Int?
    let nextClassName: String?
    let currentTime: Date
    let lunchEndTime: Date
    
    private var timeRemaining: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        
        let timeInterval = lunchEndTime.timeIntervalSince(currentTime)
        return formatter.string(from: max(0, timeInterval)) ?? ""
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                )
            
            VStack(spacing: 5) {
                Text("Lunch Break")
                    .font(.headline)
                
                Text("Time remaining: \(timeRemaining)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let nextClassPeriod = nextClassPeriod, let nextClassName = nextClassName {
                    let components = nextClassName.components(separatedBy: "\n").filter { !$0.isEmpty }
                    let subjectName = components.count > 1 ? components[1] : nextClassName
                    
                    Text("Next class: Period \(nextClassPeriod) - \(subjectName)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .glassmorphicCard()
    }
}
