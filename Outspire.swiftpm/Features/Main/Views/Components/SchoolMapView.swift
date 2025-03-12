import SwiftUI
import MapKit

struct SchoolMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let isInChina: Bool
    
    var body: some View {
        ZStack {
            Map {
                // School marker - properly convert coordinates for China
                let schoolCoord = isInChina ? 
                    CoordinateConverter.coordinateHandler(LocationManager.schoolCoordinate) : 
                    LocationManager.schoolCoordinate
                    
                Marker("WFLA Campus", coordinate: schoolCoord)
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
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchButton()
                MapUserLocationButton()
            }
            
            // Overlaid button for navigation action
            VStack {
                Spacer()
                Button(action: openInMaps) {
                    Text("Open in Maps")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemBackground)) // Use system background for dark mode support
                                .shadow(color: Color.primary.opacity(0.15), radius: 3, x: 0, y: 1)
                        )
                        .foregroundColor(Color.primary) // Use primary color for text to support dark mode
                }
                .padding(10)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func openInMaps() {
        // Get proper school coordinates based on region
        let schoolCoord = isInChina ? 
            CoordinateConverter.coordinateHandler(LocationManager.schoolCoordinate) : 
            LocationManager.schoolCoordinate
            
        let schoolPlacemark = MKPlacemark(coordinate: schoolCoord)
        let mapItem = MKMapItem(placemark: schoolPlacemark)
        mapItem.name = "WFLA International School"
        
        // If user location is available, get directions to school
        if let userLocation = userLocation {
            // Ensure the user location is also properly converted if in China
            let adjustedUserCoordinate = isInChina ? 
                CoordinateConverter.coordinateHandler(userLocation) : 
                userLocation
            
            let userPlacemark = MKPlacemark(coordinate: adjustedUserCoordinate)
            let userMapItem = MKMapItem(placemark: userPlacemark)
            
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } else {
            // Just show the school location
            mapItem.openInMaps()
        }
    }
}
