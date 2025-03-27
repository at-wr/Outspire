import Foundation
import CoreLocation
import UserNotifications

class PermissionManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var locationCompletionHandler: ((CLAuthorizationStatus) -> Void)?

    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        locationManager.delegate = self

        // Set locationManager properties
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

        // Initialize with current status
        locationAuthorizationStatus = locationManager.authorizationStatus

        // Check current notification status
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationAuthorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Location Permission Methods

    func checkLocationPermission(completion: @escaping (CLAuthorizationStatus) -> Void) {
        let status = locationManager.authorizationStatus
        locationAuthorizationStatus = status
        completion(status)
    }

    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        let status = locationManager.authorizationStatus
        locationAuthorizationStatus = status

        // If already determined, return the current status
        if status != .notDetermined {
            completion(status == .authorizedWhenInUse || status == .authorizedAlways)
            return
        }

        // Store completion handler to call when authorization changes
        locationCompletionHandler = { status in
            completion(status == .authorizedWhenInUse || status == .authorizedAlways)
        }

        // Request authorization - first try when in use
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission(completion: @escaping (Bool) -> Void) {
        let status = locationManager.authorizationStatus

        // If already has always permission, return true
        if status == .authorizedAlways {
            completion(true)
            return
        }

        // If already has when in use, request upgrade to always
        if status == .authorizedWhenInUse {
            locationCompletionHandler = { status in
                completion(status == .authorizedAlways)
            }
            locationManager.requestAlwaysAuthorization()
            return
        }

        // Otherwise, request when in use first
        requestLocationPermission { [weak self] granted in
            if granted {
                self?.locationCompletionHandler = { status in
                    completion(status == .authorizedAlways)
                }
                self?.locationManager.requestAlwaysAuthorization()
            } else {
                completion(false)
            }
        }
    }

    // MARK: - Notification Permission Methods

    func checkNotificationPermission(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationAuthorizationStatus = settings.authorizationStatus
                completion(settings.authorizationStatus)
            }
        }
    }

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission request error: \(error.localizedDescription)")
                }

                // Update current status
                self?.checkNotificationPermission { _ in }

                completion(granted)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationAuthorizationStatus = status

        if let completionHandler = locationCompletionHandler {
            completionHandler(status)
            locationCompletionHandler = nil
        }

        // Post notification for other parts of the app to handle
        NotificationCenter.default.post(name: .locationAuthorizationChanged, object: status)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

// Add notification name for location authorization changes
extension Notification.Name {
    static let locationAuthorizationChanged = Notification.Name("locationAuthorizationChanged")
}
