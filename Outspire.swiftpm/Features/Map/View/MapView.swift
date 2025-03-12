import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    // Define the initial region
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.1476, longitude: 121.4079),
        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015) // Adjust for campus size
    )
    
    // State for map position to control the map's view
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 31.1476, longitude: 121.4079),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )
    
    // Campus locations array
    let campusLocations = [
        CampusLocation(name: "WFLA International Campus", coordinate: CLLocationCoordinate2D(latitude: 31.1476, longitude: 121.4079))
    ]
    
    var body: some View {
        Map(position: $position) {
            // Add markers for each campus location
            ForEach(campusLocations) { location in
                Marker(location.name, coordinate: location.coordinate)
                    .tint(.red) // Customize the marker color
            }
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton() // Button to center on user
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensures map fills available space
        .onAppear {
            // Request location permission
            let locationManager = CLLocationManager()
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

struct CampusLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    MapView()
}
