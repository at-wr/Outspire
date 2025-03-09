import SwiftUI

struct SettingsView: View {
    @Binding var showSettingsSheet: Bool
    @EnvironmentObject var sessionService: SessionService
    @State private var navigationPath = NavigationPath()
    @State private var viewRefreshID = UUID()
    
    enum SettingsMenu: String, Hashable, CaseIterable {
        case account
        case general
        case export
        case license
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                // Account section
                Section {
                    NavigationLink(value: SettingsMenu.account) {
                        ProfileHeaderView()
                    }
                }
                
                // General settings section
                Section {
                    ForEach(SettingsMenu.allCases, id: \.self) { item in
                        if item != .account {
                            NavigationLink(value: item) {
                                MenuItemView(item: item)
                            }
                        }
                    }
                }
                
                // Links section
                Section {
                    Link(destination: URL(string: "https://github.com/at-wr/Outspire/")!) {
                        Label("GitHub Repository", systemImage: "globe.asia.australia")
                            .foregroundStyle(.primary)
                    }
                    Link(destination: URL(string: "https://github.com/at-wr/Outspire?tab=readme-ov-file#privacy-policy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                            .foregroundStyle(.primary)
                    }
                    Link(destination: URL(string: "https://github.com/at-wr/Outspire/issues/new/choose")!) {
                        Label("Report an Issue", systemImage: "exclamationmark.bubble")
                            .foregroundStyle(.primary)
                    }
                } footer: {
                    Text("Made by Alan Ye @WFLA\nThis is an open-source project, licensed under MIT.\nPlease leave a star on GitHub if you like ✨")
                        .font(.caption)
                }
            }
            .id(viewRefreshID)
            .navigationTitle("Settings")
            .toolbar {
                Button(action: {
                    showSettingsSheet = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationDestination(for: SettingsMenu.self) { destination in
                destinationView(for: destination)
            }
            .onReceive(NotificationCenter.default.publisher(for: .authenticationStatusChanged)) { notification in
                DispatchQueue.main.async {
                    viewRefreshID = UUID()
                    if let action = notification.userInfo?["action"] as? String {
                        if action == "logout" || action == "signedin" {
                            navigationPath = NavigationPath()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: SettingsMenu) -> some View {
        switch destination {
        case .account:
            AccountWithNavigation()
        case .general:
            SettingsGeneralView()
        case .export:
            ExportView()
        case .license:
            LicenseView()
        }
    }
}

// AccountWithNavigation remains unchanged
struct AccountWithNavigation: View {
    @StateObject private var viewModel = AccountViewModel()
    @EnvironmentObject var sessionService: SessionService
    
    var body: some View {
        AccountView(viewModel: viewModel)
            .navigationTitle(sessionService.isAuthenticated ? "Account" : "Sign In")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if !sessionService.isAuthenticated && viewModel.captchaImageData == nil {
                    viewModel.fetchCaptchaImage()
                }
            }
    }
}
