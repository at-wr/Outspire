import SwiftUI
import MapKit

struct SchoolMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let isInChina: Bool
    
    var body: some View {
        Map {
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
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
}
