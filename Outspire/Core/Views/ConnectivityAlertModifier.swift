import SwiftUI

struct ConnectivityAlertsViewModifier: ViewModifier {
    @ObservedObject var connectivityManager = ConnectivityManager.shared

    func body(content: Content) -> some View {
        content
            // Alert for no internet connection
            .alert("No Internet Connection", isPresented: $connectivityManager.showNoInternetAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please check your internet connection and try again.")
            }

            // Alert for relay server suggestion
            .alert("Connection Issues", isPresented: $connectivityManager.showRelayAlert) {
                Button("Not Now", role: .cancel) {
                    connectivityManager.userDismissedRelayPrompt()
                }
                Button("Use Relay") {
                    connectivityManager.userSelectedRelay()
                }
            } message: {
                Text("Possibly due to GeoIP or Network restrictions, direct connection to the school server is not available. Would you like to use the Relay server instead?")
            }

            // Alert for direct connection suggestion
            .alert("Faster Connection Available", isPresented: $connectivityManager.showDirectAlert) {
                Button("Not Now", role: .cancel) {
                    connectivityManager.userDismissedDirectPrompt()
                }
                Button("Switch to Direct") {
                    connectivityManager.userSelectedDirect()
                }
            } message: {
                Text("Direct connection to the school server is now available. Would you like to switch for faster performance?")
            }
    }
}

extension View {
    func withConnectivityAlerts() -> some View {
        modifier(ConnectivityAlertsViewModifier())
    }
}
