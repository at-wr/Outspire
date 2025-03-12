import SwiftUI
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var travelTimeToSchool: TimeInterval?
    @Published var travelDistance: CLLocationDistance?
    
    // WFLA Shanghai Campus coordinates
    static let schoolLocation = CLLocation(latitude: 31.1476, longitude: 121.4079)
    static let schoolCoordinate = CLLocationCoordinate2D(latitude: 31.1476, longitude: 121.4079)
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
        requestAuthorization()
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
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
    
    func calculateETAToSchool(isInChina: Bool, completion: @escaping () -> Void) {
        guard let userLocation = userLocation,
              authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            self.travelTimeToSchool = nil
            self.travelDistance = nil
            completion()
            return
        }
        
        // Check if we should recalculate
        if let lastCalc = lastETACalculationTime, Date().timeIntervalSince(lastCalc) < etaRecalculationInterval {
            completion()
            return
        }
        
        // Use different calculation methods depending on region
        if isInChina {
            // Apply coordinate conversion for Chinese MapKit
            calculateETAWithChineseMapKit(from: userLocation.coordinate, isInChina: isInChina) {
                self.lastETACalculationTime = Date()
                completion()
            }
        } else {
            // For non-Chinese regions, just estimate based on distance
            let distance = userLocation.distance(from: LocationManager.schoolLocation)
            self.travelDistance = distance
            
            // Rough estimate: 30 km/h average speed in city traffic
            self.travelTimeToSchool = distance / (30 * 1000 / 3600)
            self.lastETACalculationTime = Date()
            completion()
        }
    }
    
    private func calculateETAWithChineseMapKit(from userCoordinate: CLLocationCoordinate2D, isInChina: Bool, completion: @escaping () -> Void) {
        let request = MKDirections.Request()
        
        // Apply GCJ-02 conversion for Chinese MapKit if needed
        let sourceCoordinate = isInChina ? CoordinateConverter.coordinateHandler(userCoordinate) : userCoordinate
        let destCoordinate = isInChina ? CoordinateConverter.coordinateHandler(LocationManager.schoolCoordinate) : LocationManager.schoolCoordinate
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destCoordinate)
        
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculateETA { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self, let response = response, error == nil else {
                    self?.travelTimeToSchool = nil
                    self?.travelDistance = nil
                    completion()
                    return
                }
                
                self.travelTimeToSchool = response.expectedTravelTime
                self.travelDistance = response.distance
                completion()
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
            
            // Check if we should update region
            if let lastCheck = lastRegionCheckLocation, 
               location.distance(from: lastCheck) > regionCheckThreshold {
                // Region check should be performed now
                NotificationCenter.default.post(name: .locationSignificantChange, object: nil)
                lastRegionCheckLocation = location
            } else if lastRegionCheckLocation == nil {
                // First time getting location
                NotificationCenter.default.post(name: .locationSignificantChange, object: nil)
                lastRegionCheckLocation = location
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}

extension Notification.Name {
    static let locationSignificantChange = Notification.Name("locationSignificantChange")
}
