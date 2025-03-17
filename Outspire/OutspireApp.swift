import SwiftUI
import Toasts
import UserNotifications
import CoreLocation

@main
struct OutspireApp: App {
    @StateObject private var sessionService = SessionService.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var regionChecker = RegionChecker.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Add observer for widget data updates
    @StateObject private var widgetDataManager = WidgetDataManager()
    
    @UIApplicationDelegateAdaptor(OutspireAppDelegate.self) var appDelegate
    
    init() {
        // Initialize app settings
        if UserDefaults.standard.object(forKey: "useSSL") == nil {
            Configuration.useSSL = false
        }
        
        // Register the Live Activity widget
        if #available(iOS 16.1, *) {
            LiveActivityRegistration.registerLiveActivities()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavSplitView()
                .environmentObject(sessionService)
                .environmentObject(locationManager)
                .environmentObject(regionChecker)
                .environmentObject(notificationManager)
                .installToast(position: .top)
                .environmentObject(widgetDataManager)
                .onAppear {
                    // Setup widget data sharing
                    setupWidgetDataSharing()
                }
        }
    }
    
    private func setupWidgetDataSharing() {
        // Ensure app group container exists
        guard let _ = UserDefaults(suiteName: "group.dev.wrye.Outspire") else {
            print("Failed to access app group container")
            return
        }
        
        // Share authentication state with widgets
        widgetDataManager.updateAuthenticationState(isAuthenticated: sessionService.isAuthenticated)
        
        // Share holiday mode settings with widgets
        widgetDataManager.updateHolidayMode(
            isEnabled: Configuration.isHolidayMode,
            hasEndDate: Configuration.holidayHasEndDate,
            endDate: Configuration.holidayEndDate
        )
        
        // Observe authentication changes
        NotificationCenter.default.addObserver(forName: .authStateDidChange, object: nil, queue: .main) { _ in
            self.widgetDataManager.updateAuthenticationState(isAuthenticated: self.sessionService.isAuthenticated)
        }
        
        // Observe holiday mode changes
        NotificationCenter.default.addObserver(forName: .holidayModeDidChange, object: nil, queue: .main) { _ in
            self.widgetDataManager.updateHolidayMode(
                isEnabled: Configuration.isHolidayMode,
                hasEndDate: Configuration.holidayHasEndDate,
                endDate: Configuration.holidayEndDate
            )
        }
        
        // Observe timetable data changes
        NotificationCenter.default.addObserver(forName: .timetableDataDidChange, object: nil, queue: .main) { notification in
            if let timetable = notification.userInfo?["timetable"] as? [[String]] {
                self.widgetDataManager.updateTimetableData(timetable: timetable)
            }
        }
    }
}

class OutspireAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register for user notifications
        UNUserNotificationCenter.current().delegate = LocationManager.shared
        
        // Register notification categories for interactive notifications
        NotificationManager.shared.registerNotificationCategories()
        
        // Initialize with proper permissions if onboarding is completed
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if hasCompletedOnboarding {
            // Setup location services if onboarding is complete
            setupServicesAfterOnboarding()
        }
        
        return true
    }
    
    private func setupServicesAfterOnboarding() {
        // Start location manager if permission was granted during onboarding
        if LocationManager.shared.authorizationStatus == .authorizedWhenInUse || 
            LocationManager.shared.authorizationStatus == .authorizedAlways {
            LocationManager.shared.startUpdatingLocation()
        }
        
        // Schedule notifications if permission was granted during onboarding
        NotificationManager.shared.checkAuthorizationStatus { status in
            if status == .authorized {
                NotificationManager.shared.scheduleMorningETANotification()
            }
        }
    }
}

// Widget Data Manager for sharing data with widgets
class WidgetDataManager: ObservableObject {
    private let appGroupDefaults = UserDefaults(suiteName: "group.dev.wrye.Outspire")
    
    init() {
        // Initialize with default values
        updateAuthenticationState(isAuthenticated: false)
    }
    
    // Update authentication state for widgets
    func updateAuthenticationState(isAuthenticated: Bool) {
        appGroupDefaults?.set(isAuthenticated, forKey: "isAuthenticated")
    }
    
    // Update timetable data for widgets
    func updateTimetableData(timetable: [[String]]) {
        if let encoded = try? JSONEncoder().encode(timetable) {
            appGroupDefaults?.set(encoded, forKey: "widgetTimetableData")
        }
    }
    
    // Update holiday mode settings for widgets
    func updateHolidayMode(isEnabled: Bool, hasEndDate: Bool, endDate: Date) {
        appGroupDefaults?.set(isEnabled, forKey: "isHolidayMode")
        appGroupDefaults?.set(hasEndDate, forKey: "holidayHasEndDate")
        appGroupDefaults?.set(endDate, forKey: "holidayEndDate")
    }
}

// Notification names for widget data updates
extension Notification.Name {
    static let authStateDidChange = Notification.Name("authStateDidChange")
    static let holidayModeDidChange = Notification.Name("holidayModeDidChange")
    static let timetableDataDidChange = Notification.Name("timetableDataDidChange")
    static let authenticationStatusChanged = Notification.Name("authenticationStatusChanged")
}

/// Helper class to register Live Activities
@available(iOS 16.1, *)
class LiveActivityRegistration {
    static func registerLiveActivities() {
        // We don't directly reference the OutspireWidgetLiveActivity class here
        // Instead we just ensure the ClassActivityAttributes type is ready
        _ = ClassActivityAttributes(
            className: "",
            roomNumber: "",
            teacherName: ""
        )
    }
}
