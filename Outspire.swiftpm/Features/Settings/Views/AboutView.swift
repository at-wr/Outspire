import SwiftUI

struct AboutView: View {
    
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("0.4.2")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("Developer", systemImage: "person")
                    Spacer()
                    Text("Alan Ye @ WFLA")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("License", systemImage: "key.card")
                    Spacer()
                    Text("Open-sourced under MIT")
                        .foregroundStyle(.secondary)
                }
                
            } footer: {
                Text("Please leave a star on GitHub if you like ✨")
                    .font(.caption)
            }
        }
        .navigationTitle("About")
        .contentMargins(.vertical, 10.0)
    }
}

