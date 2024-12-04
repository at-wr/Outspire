import SwiftUI

struct SettingsView: View {
    @Binding var showSettingsSheet: Bool
    
    enum SettingsMenu: String, Hashable {
        case account
        case general
        case export
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: SettingsMenu.account) {
                        Label("Account", systemImage: "person.fill.viewfinder")
                    }
                    NavigationLink(value: SettingsMenu.general) {
                        Label("General", systemImage: "switch.2")
                    }
                }
                Section {
                    NavigationLink(value: SettingsMenu.export) {
                        Label("Export App Package", systemImage: "shippingbox")
                    }
                    Link(destination: URL(string: "mailto:me@wrye.dev")!) {
                        Label("E-mail", systemImage: "envelope")
                            .foregroundStyle(.primary)
                    }
                } footer: {
                    Text("Made by Alan Ye @WFLA\nThis app was created entirely with Swift Playground.")
                        .font(.caption)
                        .contentMargins(.top, 10)
                }
            }
            .contentMargins(.top, 10)
            .navigationTitle("Settings")
            .toolbar {
                Button(action: {
                    showSettingsSheet = false
                }, label: {
                    Image(systemName: "checkmark.circle")
                })
            }
            .navigationDestination(for: SettingsMenu.self) { destination in
                switch destination {
                case .account:
                    AccountDetailsView()
                case .general:
                    SettingsGeneralView()
                case .export:
                    ExportView()
                }
            }
        }
    }
}
