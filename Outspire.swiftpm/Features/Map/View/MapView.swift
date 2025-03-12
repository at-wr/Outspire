import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.1476, longitude: 121.4079), // Shanghai 31.145659384995238, 121.41293856157947
        //31.14755° N, 121.40786° E
        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015) // Adjust for campus size
    )
    
    let campusLocations = [
        CampusLocation(name: "International Campus", coordinate: CLLocationCoordinate2D(latitude: 31.1476, longitude: 121.4079)),    ]
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: campusLocations) { location in
            MapPin(coordinate: location.coordinate, tint: .red)
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
