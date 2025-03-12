import SwiftUI
import MapKit
import CoreLocation

// lol thanks to iRingo
// https://nsringo.github.io/guide/GeoServices/maps.html

class RegionChecker: ObservableObject {
    @Published var regionCode: String? = nil
    
    func fetchRegionCode() {
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
    
    func isChinaRegion() -> Bool {
        return regionCode == "CN"
    }
}
