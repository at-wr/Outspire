import SwiftUI
import Toasts
import UserNotifications
import CoreLocation

@main
struct OutspireApp: App {
    @StateObject private var sessionService = SessionService.shared
    @UIApplicationDelegateAdaptor(OutspireAppDelegate.self) var appDelegate
    
    init() {
        // Initialize app settings
        if UserDefaults.standard.object(forKey: "useSSL") == nil {
            Configuration.useSSL = false
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavSplitView()
                .environmentObject(sessionService)
                .installToast(position: .top)
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
