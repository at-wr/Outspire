import SwiftUI

struct SettingsView: View {
    @Binding var showSettingsSheet: Bool
    @EnvironmentObject var sessionService: SessionService
    @State private var navigationPath = NavigationPath()
    @State private var viewRefreshID = UUID()
    
    enum SettingsMenu: String, Hashable {
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
                        HStack(spacing: 12) {
                            // Profile avatar
                            Image(systemName: sessionService.isAuthenticated ? "person.circle.fill" : "person.fill.viewfinder")
                                .font(.system(size: 28))
                                .foregroundStyle(sessionService.isAuthenticated ? Color(.cyan) : .gray)
                                .frame(width: 36, height: 36)
                            
                            // User info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sessionService.isAuthenticated ? 
                                     (sessionService.userInfo?.nickname ?? sessionService.userInfo?.studentname ?? "Account") : 
                                        "Sign In")
                                .font(.headline)
                                
                                if sessionService.isAuthenticated, let username = sessionService.userInfo?.studentid {
                                    Text("ID: \(username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if !sessionService.isAuthenticated {
                                    Text("for personalized experience.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                // .listRowBackground(sessionService.isAuthenticated ? Color(UIColor.systemBackground) : nil)
                
                // General settings section
                Section {
                    NavigationLink(value: SettingsMenu.general) {
                        Label("General", systemImage: "switch.2")
                    }
                    NavigationLink(value: SettingsMenu.export) {
                        Label("Export App Package", systemImage: "shippingbox")
                    }
                    NavigationLink(value: SettingsMenu.license) {
                        Label("Licenses", systemImage: "doc.text")
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
                    Text("Made by Alan Ye @WFLA\nThis is an open-source project, licensed under AGPLv3.\nPlease leave a star on GitHub if you like ✨")
                        .font(.caption)
                }
            }
            .id(viewRefreshID) // Force refresh when needed
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
            .onReceive(NotificationCenter.default.publisher(for: .authenticationStatusChanged)) { notification in
                // Force refresh the view when authentication changes
                DispatchQueue.main.async {
                    viewRefreshID = UUID()
                    
                    // If this was a logout, reset navigation path to root
                    if (notification.userInfo?["action"] as? String) == "logout" {
                        navigationPath = NavigationPath()
                    }
                    if (notification.userInfo?["action"] as? String) == "signedin" {
                        navigationPath = NavigationPath()
                    }
                }
            }
        }
    }
}

// Redesigned account wrapper that works within parent navigation
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
