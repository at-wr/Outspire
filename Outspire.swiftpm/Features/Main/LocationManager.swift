import SwiftUI
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var travelTimeToSchool: TimeInterval?
    @Published var travelDistance: CLLocationDistance?
    
    // Int'l Campus coordinates
    // 31.14704° N, 121.40758° E
    static let schoolLocation = CLLocation(latitude: 31.14704, longitude: 121.40758)
    static let schoolCoordinate = CLLocationCoordinate2D(latitude: 31.14704, longitude: 121.40758)
    static let nearSchoolThreshold: CLLocationDistance = 1000 // 1km radius
    
    // Cache to avoid frequent ETA updates
    private var lastETACalculationTime: Date?
    private let etaRecalculationInterval: TimeInterval = 300 // 5 minutes
    
    // Properties for region checking
    private var lastRegionCheckLocation: CLLocation?
    private let regionCheckThreshold: CLLocationDistance = 1000 // Check every 1km of movement
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        // Don't request authorization here - do it explicitly when needed
    }
    
    func requestAuthorization() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        // Only start if authorized and not already updating
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func isNearSchool() -> Bool {
        guard let userLocation = userLocation else { return false }
        let distance = userLocation.distance(from: LocationManager.schoolLocation)
        return distance <= LocationManager.nearSchoolThreshold
    }
    
    func distanceToSchool() -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        return userLocation.distance(from: LocationManager.schoolLocation)
    }
    
    // Calculate ETA using the appropriate method based on region
    func calculateETAToSchool(isInChina: Bool, completion: @escaping () -> Void) {
        guard let userLocation = userLocation,
              authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            self.travelTimeToSchool = nil
            self.travelDistance = nil
            completion()
            return
        }
        
        // Check if we should recalculate - avoid too frequent updates
        if let lastCalc = lastETACalculationTime, Date().timeIntervalSince(lastCalc) < etaRecalculationInterval {
            completion()
            return
        }
        
        // Save distance regardless of calculation method
        let distance = userLocation.distance(from: LocationManager.schoolLocation)
        self.travelDistance = distance
        
        // Use different calculation methods depending on region
        if isInChina {
            // Apply coordinate conversion for Chinese MapKit
            calculateETAWithMapKit(from: userLocation.coordinate, isInChina: isInChina) {
                self.lastETACalculationTime = Date()
                completion()
            }
        } else {
            // For non-Chinese regions, just estimate based on distance
            // Rough estimate: 30 km/h average speed in city traffic
            // update: roughly 20 km/h
            self.travelTimeToSchool = distance / (20 * 1000 / 3600)
            self.lastETACalculationTime = Date()
            completion()
        }
    }
    
    // Renamed and improved for both Chinese and international MapKit
    private func calculateETAWithMapKit(from userCoordinate: CLLocationCoordinate2D, isInChina: Bool, completion: @escaping () -> Void) {
        let request = MKDirections.Request()
        
        // For MKDirections in China, we need to use GCJ-02 coordinates
        // User coordinate from CoreLocation is already in the right format for the device's region
        // but the school coordinate needs conversion if in China
        let sourceCoordinate = userCoordinate
        let destCoordinate = isInChina ? 
        CoordinateConverter.coordinateHandler(LocationManager.schoolCoordinate) : 
        LocationManager.schoolCoordinate
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destCoordinate)
        
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculateETA { [weak self] response, error in
            guard let self = self, let response = response, error == nil else {
                // Fallback to distance-based estimation if directions fail
                if let distance = self?.travelDistance {
                    self?.travelTimeToSchool = distance / (20 * 1000 / 3600) // 20 km/h
                }
                completion()
                return
            }
            
            self.travelTimeToSchool = response.expectedTravelTime
            completion()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.locationManager.startUpdatingLocation()
            } else {
                self.locationManager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location
            
            // Post notification about significant location changes - but throttle them
            if let lastCheck = self.lastRegionCheckLocation {
                let distance = location.distance(from: lastCheck)
                if distance > self.regionCheckThreshold {
                    self.lastRegionCheckLocation = location
                    NotificationCenter.default.post(name: .locationSignificantChange, object: nil)
                }
            } else {
                self.lastRegionCheckLocation = location
                NotificationCenter.default.post(name: .locationSignificantChange, object: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

// Define a Notification.Name for significant location changes
extension Notification.Name {
    static let locationSignificantChange = Notification.Name("locationSignificantChange")
}
