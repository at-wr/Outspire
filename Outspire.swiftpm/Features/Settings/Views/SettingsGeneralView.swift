import SwiftUI

struct SettingsGeneralView: View {
    @State private var useSSL = Configuration.useSSL
    @State private var hideAcademicScore = Configuration.hideAcademicScore
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            Section(header: Text("Display Options")) {
                Toggle(isOn: $hideAcademicScore) {
                    Label("Hide Academic Score", systemImage: "eye.slash")
                }
                .onChange(of: hideAcademicScore) { newValue in
                    Configuration.hideAcademicScore = newValue
                }
            } footer: {
                Text("Hide the Academic Score option from the main menu")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Network")) {
                Toggle(isOn: $useSSL) {
                    Label("Enable Relay Encryption", systemImage: "lock.square")
                }
                .onChange(of: useSSL) { newValue in
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
            } footer: {
                Text("Enables Hypertext Transfer Protocol Secure. Relay Service provided by Vercel & Computerization, may slow down the connection speed.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("0.1")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .contentMargins(.vertical, 10.0)
    }
}
