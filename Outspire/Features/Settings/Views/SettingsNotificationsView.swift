import SwiftUI

struct SettingsNotificationsView: View {
    @State private var departureNotificationsEnabled = Configuration.departureNotificationsEnabled
    @State private var automaticallyStartLiveActivities = Configuration.automaticallyStartLiveActivities
    @State private var isRequestingPermission = false
    @State private var permissionDenied = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: $departureNotificationsEnabled) {
                    Label("Departure Notifications", systemImage: "bell")
                }
                .onChange(of: departureNotificationsEnabled) { _, newValue in
                    Configuration.departureNotificationsEnabled = newValue
                    if newValue {
                        isRequestingPermission = true
                        NotificationManager.shared.requestAuthorization { granted in
                            DispatchQueue.main.async {
                                isRequestingPermission = false
                                permissionDenied = !granted
                                if granted {
                                    NotificationManager.shared.scheduleMorningETANotification()
                                }
                            }
                        }
                    } else {
                        NotificationManager.shared.cancelNotification(of: .morningETA)
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
                Text("Commute Reminders")
            } footer: {
                Text("Enable to receive a morning notification reminding you to leave for school. You must grant notification permission.")
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
            } header: {
                Text("Live Activities")
            } footer: {
                Text("Enable to automatically start Live Activities for your classes. You can also start/stop them manually from the class view.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .toggleStyle(.switch)
        .navigationTitle("Notifications")
        .toolbarBackground(Color(UIColor.secondarySystemBackground))
        .contentMargins(.vertical, 10.0)
    }
}
