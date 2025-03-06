import SwiftUI

struct SettingsGeneralView: View {
    @State private var useSSL = Configuration.useSSL
    
    var body: some View {
        VStack {
            List {
                HStack {
                    Toggle(isOn: .constant(true)){
                        Label("I hate WFLA", systemImage: "person.crop.circle.badge.questionmark")
                    }
                }
                Section {
                    HStack {
                        Toggle(isOn: $useSSL) {
                            Label("Enable Relay Encryption", systemImage: "lock.square")
                        }
                        .onChange(of: useSSL) {
                            Configuration.useSSL = useSSL
                            print("Base URL updated to: \(Configuration.baseURL)")
                        }
                    }
                } header: {
                    Text("Network")
                } footer: {
                    Text("Enables Hypertext Transfer Protocol Secure. Relay Service provided by Vercel & Computerization, may slow down the connection speed.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .navigationTitle("General")
                .contentMargins(.vertical, 10.0)
            }
        }
    }
}
