import Foundation
import CoreLocation
import UserNotifications

class PermissionManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var locationCompletionHandler: ((CLAuthorizationStatus) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Location Permission Methods
    
    func checkLocationPermission(completion: @escaping (CLAuthorizationStatus) -> Void) {
        let status = locationManager.authorizationStatus
        completion(status)
    }
    
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        let status = locationManager.authorizationStatus
        
        // If already determined, return the current status
        if status != .notDetermined {
            completion(status == .authorizedWhenInUse || status == .authorizedAlways)
            return
        }
        
        // Store completion handler to call when authorization changes
        locationCompletionHandler = { status in
            completion(status == .authorizedWhenInUse || status == .authorizedAlways)
        }
        
        // Request authorization
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Notification Permission Methods
    
    func checkNotificationPermission(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission request error: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        if let completionHandler = locationCompletionHandler {
            completionHandler(status)
            locationCompletionHandler = nil
        }
        
        // Post notification for other parts of the app to handle
        NotificationCenter.default.post(name: .locationAuthorizationChanged, object: status)
    }
}

// Add notification name for location authorization changes
extension Notification.Name {
    static let locationAuthorizationChanged = Notification.Name("locationAuthorizationChanged")
}
