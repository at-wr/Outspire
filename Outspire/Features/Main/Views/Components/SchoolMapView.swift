import SwiftUI
import MapKit

struct SchoolMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let isInChina: Bool
    @Environment(\.colorScheme) private var colorScheme

    // WFLA coordinates are in WGS84 format (international format)
    // So we need to convert them to GCJ-02 when in China region
    private var schoolCoordinate: CLLocationCoordinate2D {
        isInChina ?
        CoordinateConverter.coordinateHandler(LocationManager.schoolCoordinate) :
        LocationManager.schoolCoordinate
    }

    private var adjustedUserCoordinate: CLLocationCoordinate2D? {
        guard let userLocation = userLocation else { return nil }
        // User location from Core Location already matches the device's region format,
        // so no conversion needed unless we're explicitly displaying on a map with different format
        // seems like still needs reverse convertion, lol
        return isInChina ? CoordinateConverter.reverseCoordinateHandler(userLocation) : userLocation
        // return userLocation
    }

    var body: some View {
        ZStack {
            Map {
                // School marker with properly converted coordinate
                Marker("WFLA Campus", coordinate: schoolCoordinate)
                    .tint(.red)

                // User location marker if available
                if !isInChina, let userCoordinate = adjustedUserCoordinate {
                    Marker("Your Location", coordinate: userCoordinate)
                        .tint(.blue)
                }

                // Show user location dot
                UserAnnotation()
            }
            .mapStyle(isInChina ? .standard : (colorScheme == .dark ? .hybrid : .standard))
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
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
                        .foregroundColor(.primary)
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
        // When opening in Maps, we need to ensure we're using the correct coordinate system
        // For Apple Maps in China, we need the GCJ-02 coordinates

        // Create the map item for the school with proper coordinates
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: schoolCoordinate))
        mapItem.name = "WFLA International School"

        // If user location is available, set up directions
        if let userCoordinate = adjustedUserCoordinate {
            // For directions in Maps app, let the system handle the coordinates
            // as Maps will apply the necessary transformations internally
            let userMapItem = MKMapItem.forCurrentLocation()

            MKMapItem.openMaps(
                with: [userMapItem, mapItem],
                launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                    MKLaunchOptionsShowsTrafficKey: true
                ]
            )
        } else {
            // Just show the school location
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsShowsTrafficKey: true])
        }
    }
}
