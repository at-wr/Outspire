import SwiftUI

@main
struct OutspireApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // ... existing code ...
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            // ... existing code ...
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
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
        let locationManager = LocationManager.shared
        if locationManager.authorizationStatus == .authorizedWhenInUse || 
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        // Schedule notifications if permission was granted during onboarding
        NotificationManager.shared.checkAuthorizationStatus { status in
            if status == .authorized {
                NotificationManager.shared.scheduleMorningETANotification()
            }
        }
    }
}
