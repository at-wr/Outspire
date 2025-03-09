import SwiftUI

struct EnhancedClassCard: View {
    let day: String
    let period: ClassPeriod
    let classData: String
    let currentTime: Date
    let isForToday: Bool
    let setAsToday: Bool
    let effectiveDate: Date?
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var isCurrentClass = false
    @State private var timer: Timer?
    
    private var components: [String] {
        classData.replacingOccurrences(of: "<br>", with: "\n")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
    }
    
    private var formattedCountdown: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            if Configuration.showSecondsInLongCountdown {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", hours, minutes)
            }
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with class info
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    if isForToday {
                        Text(isCurrentClass ? "Current Class" : "Upcoming Class")
                            .font(.headline)
                            .foregroundStyle(isCurrentClass ? Color.orange : Color.blue)
                    } else {
                        Text("Scheduled Class")
                            .font(.headline)
                            .foregroundStyle(Color.blue)
                    }
                    
                    Text("\(day) • Period \(period.number)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(period.timeRangeFormatted)
                    .font(.subheadline)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCurrentClass ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                    )
            }
            .padding([.horizontal, .top], 16)
            
            // Class details
            VStack(alignment: .leading, spacing: 12) {
                if components.count > 1 {
                    Text(components[1])
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                    
                    HStack(alignment: .top, spacing: 24) {
                        Label {
                            Text(components[0])
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        
                        if components.count > 2 {
                            Label {
                                Text(components[2])
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Countdown section
            if isForToday || setAsToday || Configuration.showCountdownForFutureClasses {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    HStack(alignment: .center, spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: isCurrentClass ? "timer" : "hourglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(isCurrentClass ? Color.orange : Color.blue)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(isCurrentClass ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isCurrentClass ? "Class ends in" : "Class starts in")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(formattedCountdown)
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(isCurrentClass ? Color.orange : Color.blue)
                                    .contentTransition(.numericText())
                            }
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        if isCurrentClass && (isForToday || setAsToday) {
                            CircularProgressView(progress: calculateProgress())
                                .frame(width: 36, height: 36)
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            calculateTimeRemaining()
            // Update timer every second in all cases to ensure seconds are shown correctly
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                calculateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: setAsToday) {
            calculateTimeRemaining()
        }
        .onChange(of: day) {
            calculateTimeRemaining()
        }
        .onChange(of: effectiveDate) {
            calculateTimeRemaining()
        }
    }
    
    private func calculateTimeRemaining() {
        let calendar = Calendar.current
        let now = Date() // Current real time
        
        if setAsToday && effectiveDate != nil {
            // For "Set as Today" mode with an effectiveDate
            let effectiveTime = getTimeComponents(from: now)
            let effectiveDay = getDateComponents(from: effectiveDate!)
            
            // Combine the current time with the effective date
            var effectiveNowComponents = DateComponents()
            effectiveNowComponents.year = effectiveDay.year
            effectiveNowComponents.month = effectiveDay.month
            effectiveNowComponents.day = effectiveDay.day
            effectiveNowComponents.hour = effectiveTime.hour
            effectiveNowComponents.minute = effectiveTime.minute
            effectiveNowComponents.second = effectiveTime.second
            
            guard let effectiveNow = calendar.date(from: effectiveNowComponents) else { return }
            
            // Create adjusted period times based on the effective date
            let adjustedStartTime = createAdjustedTime(from: period.startTime, onDate: effectiveDate!)
            let adjustedEndTime = createAdjustedTime(from: period.endTime, onDate: effectiveDate!)
            
            if effectiveNow >= adjustedStartTime && effectiveNow <= adjustedEndTime {
                isCurrentClass = true
                timeRemaining = adjustedEndTime.timeIntervalSince(effectiveNow)
            } else if effectiveNow < adjustedStartTime {
                isCurrentClass = false
                timeRemaining = adjustedStartTime.timeIntervalSince(effectiveNow)
            } else {
                isCurrentClass = false
                timeRemaining = 0
            }
        } else if isForToday {
            // Regular today logic remains the same
            if now >= period.startTime && now <= period.endTime {
                isCurrentClass = true
                timeRemaining = period.endTime.timeIntervalSince(now)
            } else if now < period.startTime {
                isCurrentClass = false
                timeRemaining = period.startTime.timeIntervalSince(now)
            } else {
                isCurrentClass = false
                timeRemaining = 0
            }
        } else {
            // Logic for future days (preview mode)
            guard let dayOfWeek = weekdayFromDayName(day) else { return }
            let currentWeekday = calendar.component(.weekday, from: now)
            var daysToAdd = dayOfWeek - currentWeekday
            if daysToAdd <= 0 {
                daysToAdd += 7
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: now)) else { return }
            var components = calendar.dateComponents([.year, .month, .day], from: nextDate)
            let periodStartComponents = calendar.dateComponents([.hour, .minute], from: period.startTime)
            components.hour = periodStartComponents.hour
            components.minute = periodStartComponents.minute
            components.second = 0
            
            guard let futureStartTime = calendar.date(from: components) else { return }
            isCurrentClass = false
            timeRemaining = futureStartTime.timeIntervalSince(now)
        }
    }
    
    // Helper method to create a time on a specific date
    private func createAdjustedTime(from time: Date, onDate date: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second
        
        return calendar.date(from: dateComponents) ?? date
    }
    
    private func calculateProgress() -> Double {
        let totalDuration = period.endTime.timeIntervalSince(period.startTime)
        let elapsed = totalDuration - timeRemaining
        return max(0, min(1, elapsed / totalDuration))
    }
    
    private func weekdayFromDayName(_ name: String) -> Int? {
        let dayMapping = ["Mon": 2, "Tue": 3, "Wed": 4, "Thu": 5, "Fri": 6]
        return dayMapping[name]
    }
    
    // Helper method to get time components
    private func getTimeComponents(from date: Date) -> DateComponents {
        return Calendar.current.dateComponents([.hour, .minute, .second], from: date)
    }
    
    // Helper method to get date components (year, month, day)
    private func getDateComponents(from date: Date) -> DateComponents {
        return Calendar.current.dateComponents([.year, .month, .day], from: date)
    }
}
