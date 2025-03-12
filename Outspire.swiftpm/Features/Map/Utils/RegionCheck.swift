import SwiftUI
import MapKit
import CoreLocation

// lol thanks to iRingo
// https://nsringo.github.io/guide/GeoServices/maps.html

class RegionChecker: ObservableObject {
    @Published var regionCode: String? = nil
    @Published var isTaipeiInChina: Bool = false
    
    func fetchRegionCode() {
        guard let url = URL(string: "https://gspe1-ssl.ls.apple.com/pep/gcc") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let code = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                DispatchQueue.main.async {
                    self.regionCode = code
                    if code == "CN" {
                        self.checkTaipeiRepresentation()
                    }
                }
            } else {
                print("Failed to fetch region code: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
    func isChinaRegion() -> Bool {
        return regionCode == "CN" && isTaipeiInChina
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
                        print("Taipei is shown as part of: \(country) (\(countryCode))")
                    }
                }
            } else if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
            }
        }
    }
}
