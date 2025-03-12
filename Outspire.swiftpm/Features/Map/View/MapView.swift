import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var regionChecker = RegionChecker()
    
    @State private var region: MKCoordinateRegion
    @State private var position: MapCameraPosition
    
    let campusLocations: [CampusLocation]
    let campusBoundary: [CLLocationCoordinate2D]
    
    init() {
        let baseCoordinate = CLLocationCoordinate2D(latitude: 31.1476, longitude: 121.4079)
        let initialRegion = MKCoordinateRegion(
            center: baseCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
        
        self._region = State(initialValue: initialRegion)
        self._position = State(initialValue: .region(initialRegion))
        
        self.campusLocations = [
            CampusLocation(name: "WFLA International Campus", coordinate: baseCoordinate)
        ]
        
        self.campusBoundary = [
            CLLocationCoordinate2D(latitude: 31.1470, longitude: 121.4070),
            CLLocationCoordinate2D(latitude: 31.1480, longitude: 121.4070),
            CLLocationCoordinate2D(latitude: 31.1480, longitude: 121.4088),
            CLLocationCoordinate2D(latitude: 31.1470, longitude: 121.4088)
        ]
    }
    
    var body: some View {
        Map(position: $position) {
            ForEach(campusLocations) { location in
                let coordinate = regionChecker.isChinaRegion() ?
                CoordinateConverter.coordinateHandler(location.coordinate) : location.coordinate
                Marker(location.name, coordinate: coordinate)
                    .tint(.red)
            }
            // Boundary polygon
            // MapPolygon(coordinates: regionChecker.isChinaRegion() ?
            //     campusBoundary.map { CoordinateConverter.coordinateHandler($0) } : campusBoundary)
            //     .foregroundStyle(.blue.opacity(0.3))
            //     .stroke(.blue, lineWidth: 2)
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            let locationManager = CLLocationManager()
            locationManager.requestWhenInUseAuthorization()
            regionChecker.fetchRegionCode()
        }
        .onChange(of: position) { newPosition in
            // Re-check region if the map position changes significantly
            regionChecker.fetchRegionCode()
        }
        .onChange(of: regionChecker.regionCode) { _ in
            // Update the map position when the region code is fetched
            if regionChecker.isChinaRegion() {
                let adjustedCoordinate = CoordinateConverter.coordinateHandler(
                    CLLocationCoordinate2D(latitude: 31.1476, longitude: 121.4079)
                )
                let newRegion = MKCoordinateRegion(
                    center: adjustedCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                )
                region = newRegion
                position = .region(newRegion)
            }
        }
    }
}

// Include the CoordinateConverter struct from the previous response here
struct CampusLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    MapView()
}
