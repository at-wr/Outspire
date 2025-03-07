import SwiftUI

struct SettingsGeneralView: View {
    @State private var useSSL = Configuration.useSSL
    @State private var hideAcademicScore = Configuration.hideAcademicScore
    @State private var showClearCacheConfirmation = false
    @State private var showCacheCleared = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: $hideAcademicScore) {
                    Label("Hide Academic Score", systemImage: "eye.slash")
                }
                .onChange(of: hideAcademicScore) { _, newValue in
                    Configuration.hideAcademicScore = newValue
                }
            } header: {
                Text("Display Options")
            } footer: {
                Text("Hide the Academic Score option from the main menu")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Toggle(isOn: $useSSL) {
                    Label("Enable Relay Encryption", systemImage: "lock.square")
                }
                .onChange(of: useSSL) { _, newValue in
                    Configuration.useSSL = newValue
                }
                
                HStack {
                    Text("Current Server:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Configuration.baseURL)
                        .font(.footnote.monospaced())
                        .padding(6)
                        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            } header: {
                Text("Network")
            } footer: {
                Text("Enables Hypertext Transfer Protocol Secure. Relay Service provided by Vercel & Computerization, may slow down the connection speed.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button(action: {
                    showClearCacheConfirmation = true
                }) {
                    HStack {
                        Label("Clear All Cache", systemImage: "trash")
                        Spacer()
                    }
                    .foregroundColor(.red)
                }
            } header: {
                Text("Data Management")
            } footer: {
                Text("This will remove all locally cached data including groups, activities, and academic records.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("0.1")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("General")
        .contentMargins(.vertical, 10.0)
        .confirmationDialog(
            "Clear Cache?",
            isPresented: $showClearCacheConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                CacheManager.clearAllCache()
                showCacheCleared = true
                
                // Auto-dismiss success message after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCacheCleared = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all cached data. You'll need to reload data from the server.")
        }
    }
}
