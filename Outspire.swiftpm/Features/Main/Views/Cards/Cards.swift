import SwiftUI

// No upcoming class card
struct NoClassCard: View {
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// School information card
struct SchoolInfoCard: View {
    let assemblyTime: String
    let arrivalTime: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Information", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// Daily schedule summary card
struct DailyScheduleCard: View {
    @ObservedObject var viewModel: ClasstableViewModel
    let dayIndex: Int
    let maxClassesToShow: Int = 3
    @State private var isExpandedSchedule = false
    
    // Convert dayIndex (0-4) to weekday (2-6, Monday-Friday)
    private var dayWeekday: Int { dayIndex + 2 }
    
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
    
    // Get a list of classes/self-study periods for the day
    private var scheduledClassesForToday: [(period: Int, data: String, isSelfStudy: Bool)] {
        guard !viewModel.timetable.isEmpty else { return [] }
        
        let maxRow = min(viewModel.timetable.count, maxPeriodsForDay + 1)
        return (1..<maxRow).compactMap { row in
            guard row < viewModel.timetable.count && dayIndex + 1 < viewModel.timetable[row].count else {
                return nil
            }
            
            let classData = viewModel.timetable[row][dayIndex + 1]
            let isSelfStudy = classData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            return (
                period: row,
                data: isSelfStudy ? "Class-Free\n\nSelf-Study" : classData,
                isSelfStudy: isSelfStudy
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Today's Schedule", systemImage: "calendar.day.timeline.left")
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
            if hasClasses {
                VStack(spacing: 12) {
                    ForEach(scheduledClassesForToday.prefix(isExpandedSchedule ? scheduledClassesForToday.count : maxClassesToShow), id: \.period) { item in
                        let components = item.data
                            .replacingOccurrences(of: "<br>", with: "\n")
                            .components(separatedBy: "\n")
                            .filter { !$0.isEmpty }
                        if let period = ClassPeriodsManager.shared.classPeriods.first(where: { $0.number == item.period }),
                           !components.isEmpty {
                            ScheduleRow(
                                period: item.period,
                                time: period.timeRangeFormatted,
                                subject: components.count > 1 ? components[1] : "Class",
                                room: components.count > 2 ? components[2] : "",
                                isSelfStudy: item.isSelfStudy
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    
                    Button {
                        withAnimation {
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
            } else {
                Text("No classes scheduled for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// Sign in prompt card
struct SignInPromptCard: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.8))
                .padding(.bottom, 10)
            Text("Welcome to Outspire")
                .font(.title3)
                .fontWeight(.bold)
            Text("Sign in with your TSIMS account to view your personalized dashboard and class schedule")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Text("Go to Settings → Account → Sign In")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 10)
            Spacer()
        }
        .padding(.vertical, 80)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}
