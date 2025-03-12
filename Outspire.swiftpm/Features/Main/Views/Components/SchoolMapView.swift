import SwiftUI
import MapKit

struct SchoolMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let isInChina: Bool
    
    var body: some View {
        ZStack {
            Map(initialPosition: .region(mapRegion)) {
                // School marker
                Marker("WFLA Campus", coordinate: LocationManager.schoolCoordinate)
                    .tint(.red)
                
                // User location marker if available
                if let userLocation = userLocation {
                    // Use coordinate converter if in China
                    let adjustedCoordinate = isInChina ? 
                        CoordinateConverter.coordinateHandler(userLocation) : 
                        userLocation
                    
                    Marker("Your Location", coordinate: adjustedCoordinate)
                        .tint(.blue)
                }
                
                // Show user location dot
                UserAnnotation()
            }
            .mapStyle(.standard)
            .mapControlVisibility(.hidden) // Hide all controls
            .allowsHitTesting(false) // Disable map interaction
            
            // Overlaid button for navigation action
            Button(action: openInMaps) {
                Text("Open in Maps")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                    )
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // Calculate the appropriate region for the map
    private var mapRegion: MKCoordinateRegion {
        if let userLocation = userLocation {
            // Adjust coordinates for China if needed
            let adjustedUserCoordinate = isInChina ?
                CoordinateConverter.coordinateHandler(userLocation) :
                userLocation
            
            let adjustedSchoolCoordinate = isInChina ?
                CoordinateConverter.coordinateHandler(LocationManager.schoolCoordinate) :
                LocationManager.schoolCoordinate
            
            // Calculate midpoint between user and school
            let midLat = (adjustedUserCoordinate.latitude + adjustedSchoolCoordinate.latitude) / 2
            let midLong = (adjustedUserCoordinate.longitude + adjustedSchoolCoordinate.longitude) / 2
            
            // Calculate span to include both points with some padding
            let latDelta = abs(adjustedUserCoordinate.latitude - adjustedSchoolCoordinate.latitude) * 1.5
            let longDelta = abs(adjustedUserCoordinate.longitude - adjustedSchoolCoordinate.longitude) * 1.5
            
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLong),
                span: MKCoordinateSpan(latitudeDelta: max(0.01, latDelta), longitudeDelta: max(0.01, longDelta))
            )
        } else {
            // Default to showing just the school with a reasonable zoom level
            return MKCoordinateRegion(
                center: LocationManager.schoolCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
    }
    
    private func openInMaps() {
        let schoolPlacemark = MKPlacemark(coordinate: LocationManager.schoolCoordinate)
        let mapItem = MKMapItem(placemark: schoolPlacemark)
        mapItem.name = "WFLA International School"
        
        // If user location is available, get directions to school
        if let _ = userLocation {
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } else {
            // Just show the school location
            mapItem.openInMaps()
        }
    }
}
