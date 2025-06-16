import CoreLocation
import SwiftUI
import Toasts
import UIKit
import UserNotifications

// Create an environment object to manage settings state globally
class SettingsManager: ObservableObject {
    @Published var showSettingsSheet = false
}

@main
struct OutspireApp: App {
    @StateObject private var sessionService = SessionService.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var regionChecker = RegionChecker.shared
    @StateObject private var notificationManager = NotificationManager.shared

    // Add settings manager
    @StateObject private var settingsManager = SettingsManager()

    // Add gradient manager
    @StateObject private var gradientManager = GradientManager()

    // Add connectivity manager
    @StateObject private var connectivityManager = ConnectivityManager.shared

    // Add observer for widget data updates
    @StateObject private var widgetDataManager = WidgetDataManager()

    @UIApplicationDelegateAdaptor(OutspireAppDelegate.self) var appDelegate

    // Add URL scheme handler
    @StateObject private var urlSchemeHandler = URLSchemeHandler.shared

    // Add scene phase detection
    @Environment(\.scenePhase) private var scenePhase

    // Add NSUserActivity property to handle universal links
    @State private var userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)

    init() {
        // Initialize app settings
        if UserDefaults.standard.object(forKey: "useSSL") == nil {
            Configuration.useSSL = false
        }

        // Register the Live Activity widget
        #if !targetEnvironment(macCatalyst)
            if #available(iOS 16.1, *) {
                LiveActivityRegistration.registerLiveActivities()
            }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            NavSplitView()
                .environmentObject(sessionService)
                .environmentObject(locationManager)
                .environmentObject(regionChecker)
                .environmentObject(notificationManager)
                .environmentObject(settingsManager)  // Add settings manager
                .environmentObject(urlSchemeHandler)  // Add URL scheme handler
                .environmentObject(gradientManager)  // Add gradient manager to environment
                .environmentObject(connectivityManager)  // Add connectivity manager
                .installToast(position: .top)
                .environmentObject(widgetDataManager)
                .withConnectivityAlerts()  // Add the connectivity alerts
                .onAppear {
                    // Setup widget data sharing
                    setupWidgetDataSharing()
                    // Setup URL Scheme Handler
                    URLSchemeHandler.shared.setAppReady()
                    // Start connectivity monitoring
                    connectivityManager.startMonitoring()
                    // Schedule automatic cache cleanup
                    CacheManager.scheduleAutomaticCleanup()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Check connectivity when app becomes active
                        connectivityManager.checkConnectivity()

                        // Handle notification scheduling when app becomes active
                        NotificationManager.shared.handleAppBecameActive()

                        // Also refresh session status if needed
                        if sessionService.isAuthenticated && sessionService.userInfo == nil {
                            sessionService.fetchUserInfo { _, _ in }
                        }
                    }
                }
                // Handle URLs when app is already running
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                // Handle universal links with userActivity
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        _ = urlSchemeHandler.handleUniversalLink(url)
                    }
                }
                // Error alert for URL handling failures
                .alert(
                    "Invalid URL",
                    isPresented: $urlSchemeHandler.showErrorAlert,
                    actions: {
                        Button("OK", role: .cancel) {}
                    },
                    message: {
                        Text(urlSchemeHandler.errorMessage)
                    }
                )
        }
        #if targetEnvironment(macCatalyst)
            .commands {
                CommandGroup(after: .appSettings) {
                    Button("Settings") {
                        settingsManager.showSettingsSheet = true
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
            }
        #endif
    }

    private func setupWidgetDataSharing() {
        // Ensure app group container exists
        guard UserDefaults(suiteName: "group.dev.wrye.Outspire") != nil else {
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
        NotificationCenter.default.addObserver(
            forName: .authStateDidChange, object: nil, queue: .main
        ) { _ in
            self.widgetDataManager.updateAuthenticationState(
                isAuthenticated: self.sessionService.isAuthenticated)
        }

        // Observe holiday mode changes
        NotificationCenter.default.addObserver(
            forName: .holidayModeDidChange, object: nil, queue: .main
        ) { _ in
            self.widgetDataManager.updateHolidayMode(
                isEnabled: Configuration.isHolidayMode,
                hasEndDate: Configuration.holidayHasEndDate,
                endDate: Configuration.holidayEndDate
            )
        }

        // Observe timetable data changes
        NotificationCenter.default.addObserver(
            forName: .timetableDataDidChange, object: nil, queue: .main
        ) { notification in
            if let timetable = notification.userInfo?["timetable"] as? [[String]] {
                self.widgetDataManager.updateTimetableData(timetable: timetable)
            }
        }
    }

    // Handle incoming URL schemes
    private func handleIncomingURL(_ url: URL) {
        // Signal that sheets should be closed
        urlSchemeHandler.closeAllSheets = true

        // Only process URLs when the user is authenticated
        // or if the URL is for a screen that doesn't require authentication
        if sessionService.isAuthenticated || url.host == "today" {
            _ = urlSchemeHandler.handleURL(url)
        } else {
            // Show login required message
            urlSchemeHandler.errorMessage = "You need to be signed in to access this feature"
            urlSchemeHandler.showErrorAlert = true
        }

        // Reset closeAllSheets after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.urlSchemeHandler.closeAllSheets = false
        }
    }

    // Update the method to share club to include universal links
    private func shareClub(groupInfo: GroupInfo) {
        // Create both URLs for better sharing compatibility
        let _ = "outspire://club/\(groupInfo.C_GroupsID)"
        let universalLinkString = "https://outspire.wrye.dev/app/club/\(groupInfo.C_GroupsID)"

        // Use the universal link for sharing, as it works for non-app users too
        guard let url = URL(string: universalLinkString) else { return }

        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        {
            // On iPad, set the popover presentation controller's source
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView =
                    rootViewController.view
                activityViewController.popoverPresentationController?.sourceRect = CGRect(
                    x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0,
                    height: 0)
                activityViewController.popoverPresentationController?.permittedArrowDirections = []
            }
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

class OutspireAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
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
        if LocationManager.shared.authorizationStatus == .authorizedWhenInUse
            || LocationManager.shared.authorizationStatus == .authorizedAlways
        {
            LocationManager.shared.startUpdatingLocation()
        }

        // Use centralized notification management
        NotificationManager.shared.handleAppBecameActive()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        #if !targetEnvironment(macCatalyst)
            // Clean up Live Activities
            if #available(iOS 16.1, *) {
                ClassActivityManager.shared.cleanup()
            }
        #endif
    }

    // Handle URL scheme when app is launched from a URL
    func application(
        _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return URLSchemeHandler.shared.handleURL(url)
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
#if !targetEnvironment(macCatalyst)
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
#endif
