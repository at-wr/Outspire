import SwiftUI
import MapKit

struct SchoolMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let isInChina: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // Cache the converted coordinates to avoid recomputing
    private var schoolCoordinate: CLLocationCoordinate2D {
        isInChina ? 
            CoordinateConverter.coordinateHandler(LocationManager.schoolCoordinate) : 
            LocationManager.schoolCoordinate
    }
    
    private var adjustedUserCoordinate: CLLocationCoordinate2D? {
        guard let userLocation = userLocation else { return nil }
        return isInChina ? 
            CoordinateConverter.coordinateHandler(userLocation) : 
            userLocation
    }
    
    var body: some View {
        ZStack {
            Map {
                // School marker with cached coordinate
                Marker("WFLA Campus", coordinate: schoolCoordinate)
                    .tint(.red)
                
                // User location marker if available (using cached coordinate)
                if let adjustedCoordinate = adjustedUserCoordinate {
                    Marker("Your Location", coordinate: adjustedCoordinate)
                        .tint(.blue)
                }
                
                // Show user location dot
                UserAnnotation()
            }
            .mapStyle(colorScheme == .dark ? .hybrid : .standard) // Use hybrid for dark mode
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle() // Fixed: Using MapPitchToggle instead
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
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.15), 
                                       radius: 3, x: 0, y: 1)
                        )
                        .foregroundColor(.primary) // Use primary for proper contrast in light/dark mode
                }
                .padding(10)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), 
                radius: 8, x: 0, y: 2)
    }
    
    private func openInMaps() {
        // Use the cached coordinates for consistency
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: schoolCoordinate))
        mapItem.name = "WFLA International School"
        
        // If user location is available, get directions to school
        if let adjustedUserCoordinate = adjustedUserCoordinate {
            // Create a map item from the user's location
            let userMapItem = MKMapItem.forCurrentLocation()
            
            // Open Maps with directions
            MKMapItem.openMaps(
                with: [userMapItem, mapItem],
                launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            )
        } else {
            // Just show the school location
            mapItem.openInMaps()
        }
    }
}
