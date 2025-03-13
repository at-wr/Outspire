import SwiftUI
import MapKit
import CoreLocation

class RegionChecker: ObservableObject {
    @Published var isTaipeiInChina: Bool = false
    @Published var regionCode: String? = nil
    @Published var isCheckComplete: Bool = false
    
    init() {
        // Run the Taiwan check on initialization
        checkTaipeiRepresentation()
    }
    
    func checkRegion() {
        // Primary method to check region - uses the Taiwan test
        checkTaipeiRepresentation()
        
        // Optional: still perform URL check as a fallback or additional data point
        fetchRegionCode()
    }
    
    func isChinaRegion() -> Bool {
        // Only rely on the Taiwan check, regardless of what regionCode says
        return isTaipeiInChina
    }
    
    func fetchRegionCode() {
        // This is kept as a secondary/optional check
        guard let url = URL(string: "https://gspe1-ssl.ls.apple.com/pep/gcc") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let code = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                DispatchQueue.main.async {
                    self.regionCode = code
                }
            } else {
                print("Failed to fetch region code: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
    private func checkTaipeiRepresentation() {
        // Taipei coordinates
        let taipeiLocation = CLLocationCoordinate2D(latitude: 25.032969, longitude: 121.565418)
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: taipeiLocation.latitude, longitude: taipeiLocation.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let placemark = placemarks?.first {
                // Check how MapKit represents Taipei's country
                if let country = placemark.country, let countryCode = placemark.isoCountryCode {
                    DispatchQueue.main.async {
                        // If Taipei is shown as part of China (CN), this confirms Chinese MapKit
                        self.isTaipeiInChina = countryCode == "CN"
                        self.isCheckComplete = true
                        print("Taipei is shown as part of: \(country) (\(countryCode))")
                    }
                }
            } else if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                self.isCheckComplete = true
            }
        }
    }
}
