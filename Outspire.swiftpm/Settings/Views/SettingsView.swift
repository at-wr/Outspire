import SwiftUI

struct SettingsView: View {
    @Binding var showSettingsSheet: Bool
    @State private var selectedSettingsMenu: String?
    
    var body: some View {
        
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: AccountDetailsView(), tag: "account", selection: $selectedSettingsMenu) {
                        Label("Account", systemImage: "person.fill.viewfinder")
                    }
                    
                    NavigationLink(destination: SettingsGeneralView(), tag: "general", selection: $selectedSettingsMenu) {
                        Label("General", systemImage: "switch.2")
                    }
                }
                Section {
                    NavigationLink(destination: ExportView(), tag: "exp", selection: $selectedSettingsMenu) {
                        Label("Export App Package", systemImage: "shippingbox")
                    }
                    Link(destination: URL(string:  "mailto:me@wrye.dev")!) {
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
        }
        /*
        VStack {
            AccountDetailsView()
            SettingsGeneralView()
        }
        .contentMargins(.vertical, 10)
        .navigationTitle("Settings")
         */
    }
}

