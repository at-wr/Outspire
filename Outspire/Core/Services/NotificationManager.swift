import Foundation
import UserNotifications
import CoreLocation

class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    enum NotificationType: String {
        case morningETA = "morning_eta_notification"
    }
    
    private init() {}
    
    // Request notification permissions
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification authorization request error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
    }
    
    // Check notification permission status
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // Schedule morning ETA notification for weekdays at 6:55 AM
    func scheduleMorningETANotification() {
        // Remove any existing ETA notifications first
        cancelNotification(of: .morningETA)
        
        // Check authorization before scheduling
        checkAuthorizationStatus { status in
            // Only schedule if authorized
            guard status == .authorized else { return }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "🎒 Morning Commute to School"
            content.body = "Get ready right now to catch up before it’s too late!"
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = NotificationType.morningETA.rawValue
            
            // Create a calendar trigger for 6:55 AM on weekdays (Monday=2 to Friday=6)
            var dateComponents = DateComponents()
            dateComponents.hour = 6
            dateComponents.minute = 55
            
            // Set up a trigger for each weekday
            for weekday in 2...6 {
                dateComponents.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                // Create the request with a unique identifier per weekday
                let request = UNNotificationRequest(
                    identifier: "\(NotificationType.morningETA.rawValue)_weekday_\(weekday)",
                    content: content,
                    trigger: trigger
                )
                
                // Add the notification request
                self.notificationCenter.add(request) { error in
                    if let error = error {
                        print("Error scheduling morning ETA notification for weekday \(weekday): \(error)")
                    } else {
                        print("Scheduled morning ETA notification for weekday \(weekday)")
                    }
                }
            }
        }
    }
    
    // Cancel notifications of a specific type
    func cancelNotification(of type: NotificationType) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(type.rawValue) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // Cancel all notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // Update ETA notification when it fires
    func updateETANotificationContent(travelTime: TimeInterval?, distance: CLLocationDistance?) {
        guard let travelTime = travelTime, let distance = distance else { return }
        
        // Format travel time into minutes, rounded up
        let travelMinutes = Int(ceil(travelTime / 60))
        // Format distance in kilometers with 1 decimal place
        let distanceKm = String(format: "%.1f", distance / 1000)
        
        // Get school arrival time and determine when to leave
        let arrivalTimeString = getSchoolArrivalTime(for: getCurrentWeekday())
        let leaveByTime = calculateLeaveByTime(travelMinutes: travelMinutes)
        
        // Create a new notification to replace the initial one
        let updatedContent = UNMutableNotificationContent()
        updatedContent.title = "School Travel Time: \(travelMinutes) min"
        
        // Create a more informative and actionable message
        if let leaveBy = leaveByTime {
            updatedContent.body = "Distance: \(distanceKm) km. You should leave by \(leaveBy) to arrive \(arrivalTimeString)."
        } else {
            updatedContent.body = "Distance: \(distanceKm) km. Leave soon to arrive on time!"
        }
        
        // Add category for action buttons
        updatedContent.categoryIdentifier = "ETA_ACTIONS"
        updatedContent.sound = UNNotificationSound.default
        
        // Create a trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "eta_update_\(Date().timeIntervalSince1970)",
            content: updatedContent, 
            trigger: trigger
        )
        
        // Add the notification request
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error updating ETA notification: \(error)")
            }
        }
    }
    
    // Register notification categories with actions
    func registerNotificationCategories() {
        // Define open maps action
        let openMapsAction = UNNotificationAction(
            identifier: "OPEN_MAPS",
            title: "Open in Maps",
            options: .foreground
        )
        
        // Define ETA category with actions
        let etaCategory = UNNotificationCategory(
            identifier: "ETA_ACTIONS",
            actions: [openMapsAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the category
        notificationCenter.setNotificationCategories([etaCategory])
    }
    
    // Helper to get appropriate arrival time based on weekday
    private func getSchoolArrivalTime(for weekday: Int) -> String {
        // Weekday is 1-7 where 1 is Sunday
        switch weekday {
        case 2: return "before 7:45" // Monday
        case 3, 4, 5, 6: return "before 7:55" // Tuesday-Friday
        default: return "on time" // Weekend or error case
        }
    }
    
    // Helper to calculate when user should leave
    private func calculateLeaveByTime(travelMinutes: Int) -> String? {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Only calculate leave-by time in the morning hours
        if hour < 5 || hour > 8 {
            return nil
        }
        
        // Get current weekday (1-7, 1 is Sunday)
        let weekday = calendar.component(.weekday, from: now)
        
        // Determine target arrival time based on weekday
        var arrivalHour = 7
        var arrivalMinute = 55 // Default for Tue-Fri
        
        if weekday == 2 { // Monday
            arrivalMinute = 45
        }
        
        // Create target arrival time
        var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        targetComponents.hour = arrivalHour
        targetComponents.minute = arrivalMinute
        targetComponents.second = 0
        
        guard let targetTime = calendar.date(from: targetComponents) else {
            return nil
        }
        
        // Calculate when to leave (target time minus travel time)
        let leaveTime = targetTime.addingTimeInterval(-Double(travelMinutes * 60))
        
        // Only show leave time if it's in the future
        if leaveTime > now {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: leaveTime)
        }
        
        return nil
    }
    
    // Helper to get current weekday (1-7, 1 is Sunday)
    private func getCurrentWeekday() -> Int {
        return Calendar.current.component(.weekday, from: Date())
    }
    
    // Remove all pending notifications
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Set up notification categories
    func setupNotificationCategories() {
        // Create ETA notification category with actions
        let viewETAAction = UNNotificationAction(
            identifier: "VIEW_ETA",
            title: "View ETA",
            options: .foreground
        )
        
        let etaCategory = UNNotificationCategory(
            identifier: "MORNING_ETA",
            actions: [viewETAAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the notification categories
        UNUserNotificationCenter.current().setNotificationCategories([etaCategory])
    }
}
