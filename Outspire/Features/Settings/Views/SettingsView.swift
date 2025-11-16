import SwiftUI

struct SettingsView: View {
    @Binding var showSettingsSheet: Bool
    // When presented modally, show a close button. Default false for normal navigation.
    var isModal: Bool = false
    @EnvironmentObject var sessionService: SessionService
    @State private var viewRefreshID = UUID()
    @State private var showOnboardingSheet = false

    enum SettingsMenu: String, Hashable, CaseIterable {
        case account
        case general
        case notifications
        case gradients
        case about
        case license
        #if DEBUG
            case cache
        #endif
    }

    var body: some View {
        List {
                // Account section
                Section {
                    NavigationLink(destination: destinationView(for: .account)) {
                        ProfileHeaderView()
                    }
                }

                // General settings section
                Section {
                    NavigationLink(destination: destinationView(for: .general)) {
                        MenuItemView(item: .general)
                    }
                    NavigationLink(destination: destinationView(for: .notifications)) {
                        MenuItemView(item: .notifications)
                    }
                    NavigationLink(destination: destinationView(for: .gradients)) {
                        MenuItemView(item: .gradients)
                    }
                    NavigationLink(destination: destinationView(for: .about)) {
                        MenuItemView(item: .about)
                    }
                    NavigationLink(destination: destinationView(for: .license)) {
                        MenuItemView(item: .license)
                    }
                }

                // Links section
                Section {
                    ShareLink(
                        item: URL(string: "https://apps.apple.com/us/app/outspire/id6743143348")!,
                        message: Text(
                            "\nCheck out Outspire, an app that makes your WFLA life easier!\nWidgets, Class countdowns, CAS... \n\nDownload now on the App Store."
                        )
                    ) {
                        Label("Share Outspire", systemImage: "square.and.arrow.up")
                            .foregroundStyle(.primary)
                    }

                    Link(destination: URL(string: "https://outspire.wrye.dev")!) {
                        Label("Website", systemImage: "globe")
                            .foregroundStyle(.primary)
                    }

                    Link(
                        destination: URL(
                            string: "https://github.com/at-wr/Outspire/issues/new/choose")!
                    ) {
                        Label("Report an Issue", systemImage: "exclamationmark.bubble")
                            .foregroundStyle(.primary)
                    }
                } footer: {
                }

                #if DEBUG
                    Section("Debug Tools") {
                        Button("View Onboarding") {
                            HapticManager.shared.playButtonTap()
                            showOnboardingSheet = true
                        }
                        .foregroundStyle(.blue)

                        NavigationLink(destination: CacheStatusView()) {
                            Label("Cache Status", systemImage: "externaldrive")
                                .foregroundStyle(.primary)
                        }
                    }
                #endif
        }
        .id(viewRefreshID)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(UIColor.secondarySystemBackground))
        .toolbar {
            if isModal {
                Button(action: {
                    HapticManager.shared.playButtonTap()
                    showSettingsSheet = false
                }) {
                    #if targetEnvironment(macCatalyst)
                        Text("Close")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(6)
                            .foregroundStyle(.primary)
                    #else
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    #endif
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name.authenticationStatusChanged)
        ) { _ in
            DispatchQueue.main.async { viewRefreshID = UUID() }
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView(isPresented: $showOnboardingSheet)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SettingsMenu) -> some View {
        switch destination {
        case .account:
            AccountWithNavigation()
        case .notifications:
            SettingsNotificationsView()
        case .general:
            SettingsGeneralView()
        case .gradients:
            GradientSettingsView()
        case .about:
            AboutView()
        case .license:
            LicenseView()
        #if DEBUG
            case .cache:
                CacheStatusView()
        #endif
        }
    }
}

struct AccountWithNavigation: View {
    @EnvironmentObject var sessionService: SessionService

    var body: some View {
        Group {
            AccountV2View()
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(UIColor.secondarySystemBackground))
    }
}
