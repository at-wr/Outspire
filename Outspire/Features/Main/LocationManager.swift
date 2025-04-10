import SwiftUI
import CoreLocation
import MapKit
import UserNotifications

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var travelTimeToSchool: TimeInterval?
    @Published var travelDistance: CLLocationDistance?

    static let shared = LocationManager()

    static let schoolLocation = CLLocation(latitude: 31.14704, longitude: 121.40758)
    static let schoolCoordinate = CLLocationCoordinate2D(latitude: 31.14704, longitude: 121.40758)
    static let nearSchoolThreshold: CLLocationDistance = 1000

    private var lastETACalculationTime: Date?
    private let etaRecalculationInterval: TimeInterval = 300

    private var lastRegionCheckLocation: CLLocation?
    private let regionCheckThreshold: CLLocationDistance = 1000

    private var lastNotifiedTravelTime: TimeInterval?
    private var significantChangeThreshold: TimeInterval = 300

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true

        UNUserNotificationCenter.current().delegate = self

        setupLocationAuthorizationObserver()

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func requestAuthorization() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startUpdatingLocation() {
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

        func calculateETAToSchool(isInChina: Bool, completion: @escaping () -> Void) {
        guard let userLocation = userLocation,
              authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            self.travelTimeToSchool = nil
            self.travelDistance = nil
            completion()
            return
        }

        if let lastCalc = lastETACalculationTime, Date().timeIntervalSince(lastCalc) < etaRecalculationInterval {
            completion()
            return
        }

        let distance = userLocation.distance(from: LocationManager.schoolLocation)
        self.travelDistance = distance

        let previousTravelTime = self.travelTimeToSchool

            if isInChina {
                    calculateETAWithMapKit(from: userLocation.coordinate, isInChina: isInChina) {
                self.lastETACalculationTime = Date()
                self.checkForSignificantETAChanges(previousTime: previousTravelTime)
                completion()
            }
        } else {
            self.travelTimeToSchool = distance / (20 * 1000 / 3600)
            self.lastETACalculationTime = Date()
            self.checkForSignificantETAChanges(previousTime: previousTravelTime)
            completion()
        }
    }

    private func calculateETAWithMapKit(from userCoordinate: CLLocationCoordinate2D, isInChina: Bool, completion: @escaping () -> Void) {
        let request = MKDirections.Request()

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
                if let distance = self?.travelDistance {
                    self?.travelTimeToSchool = distance / (20 * 1000 / 3600)
                }
                completion()
                return
            }

            self.travelTimeToSchool = response.expectedTravelTime
            completion()
        }
    }

    private func checkForSignificantETAChanges(previousTime: TimeInterval?) {
        guard let currentTime = travelTimeToSchool, let previousTime = previousTime else { return }

    let difference = abs(currentTime - previousTime)
        if difference > significantChangeThreshold {
            NotificationCenter.default.post(
                name: .travelTimeSignificantChange,
                object: nil,
                userInfo: [
                    "travelTime": currentTime,
                    "previousTime": previousTime,
                    "distance": travelDistance ?? 0
                ]
            )
        }
    }

    private func setupLocationAuthorizationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationAuthorizationChange(_:)),
            name: .locationAuthorizationChanged,
            object: nil
        )
    }

    @objc private func handleLocationAuthorizationChange(_ notification: Notification) {
        if let status = notification.object as? CLAuthorizationStatus {
            DispatchQueue.main.async {
                self.authorizationStatus = status

                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    self.locationManager.startUpdatingLocation()
                } else {
                    self.locationManager.stopUpdatingLocation()
                }
            }
        }
    }

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

    func handleMorningETANotification() {
            let regionChecker = RegionChecker.shared
        regionChecker.fetchRegionCode()

        lastETACalculationTime = nil

        startUpdatingLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.calculateETAToSchool(isInChina: regionChecker.isChinaRegion()) {
                NotificationManager.shared.updateETANotificationContent(
                    travelTime: self.travelTimeToSchool,
                    distance: self.travelDistance
                )

                self.lastNotifiedTravelTime = self.travelTimeToSchool

                self.stopUpdatingLocation()
            }
        }
    }
}

extension Notification.Name {
    static let locationSignificantChange = Notification.Name("locationSignificantChange")
    static let travelTimeSignificantChange = Notification.Name("travelTimeSignificantChange")
}
