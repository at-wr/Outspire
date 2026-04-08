import SwiftUI
import UserNotifications

struct SettingsNotificationsView: View {
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            Section {
                // Current permission status
                HStack {
                    Label("Notification Status", systemImage: "app.badge")
                    Spacer()
                    Text(notificationStatusText)
                        .foregroundColor(notificationStatusColor)
                }

                if notificationStatus == .denied {
                    Button(action: openSettings) {
                        Label("Open System Settings", systemImage: "gear")
                            .foregroundColor(.blue)
                    }
                }
            } header: {
                Text("Permissions")
            } footer: {
                Text("Notifications must be enabled in Settings to receive alerts from Outspire.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Notifications")
        .contentMargins(.vertical, 10.0)
        .onAppear {
            checkNotificationPermission()
        }
    }

    // Check the current notification permission status
    private func checkNotificationPermission() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            self.notificationStatus = status
        }
    }

    // Helper to open the app's settings in iOS Settings
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // Format the notification status as text
    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized:
            return "Allowed"
        case .denied:
            return "Denied"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }

    // Color coding for the permission status
    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}
