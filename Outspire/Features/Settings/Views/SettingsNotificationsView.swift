import SwiftUI
import UserNotifications

struct SettingsNotificationsView: View {
    @State private var departureNotificationsEnabled = Configuration.departureNotificationsEnabled
    @State private var departureNotificationTime = Configuration.departureNotificationTime
    @State private var automaticallyStartLiveActivities = Configuration
        .automaticallyStartLiveActivities
    @State private var isRequestingPermission = false
    @State private var permissionDenied = false
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

            Section {
                Toggle(isOn: $departureNotificationsEnabled) {
                    Label("Departure Reminder", systemImage: "car")
                }
                .onChange(of: departureNotificationsEnabled) { _, newValue in
                    Configuration.departureNotificationsEnabled = newValue
                    if newValue {
                        isRequestingPermission = true
                        NotificationManager.shared.requestAuthorization { granted in
                            DispatchQueue.main.async {
                                isRequestingPermission = false
                                permissionDenied = !granted
                                // Use centralized notification management
                                NotificationManager.shared.handleNotificationSettingsChange()
                                // Refresh permission status after request
                                checkNotificationPermission()
                            }
                        }
                    } else {
                        // Use centralized notification management
                        NotificationManager.shared.handleNotificationSettingsChange()
                    }
                }
                .disabled(notificationStatus == .denied)

                if departureNotificationsEnabled && notificationStatus == .authorized {
                    HStack {
                        Label("Notification Time", systemImage: "clock")
                        Spacer()
                        DatePicker(
                            "Select time",
                            selection: $departureNotificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .onChange(of: departureNotificationTime) { _, newValue in
                            Configuration.departureNotificationTime = newValue
                            // Use centralized notification management
                            NotificationManager.shared.handleNotificationSettingsChange()
                        }
                    }
                }

                if isRequestingPermission {
                    ProgressView("Requesting Notification Permission…")
                }
                if permissionDenied {
                    Text("Permission denied. Please enable notifications in Settings.")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text(
                    "Enable to receive a morning notification reminding you to leave for school."
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }

            Section {
                Toggle(isOn: $automaticallyStartLiveActivities) {
                    Label("Automatic Live Activities", systemImage: "bolt")
                }
                .onChange(of: automaticallyStartLiveActivities) { _, newValue in
                    Configuration.automaticallyStartLiveActivities = newValue
                }
                .disabled(notificationStatus == .denied)
            } header: {
                Text("Live Activities")
            } footer: {
                Text(
                    "Enable to automatically start Live Activities for your classes."
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }
        }
        .toggleStyle(.switch)
        .navigationTitle("Notifications")
        .toolbarBackground(Color(UIColor.secondarySystemBackground))
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
