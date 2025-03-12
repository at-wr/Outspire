import SwiftUI

struct AboutView: View {
    
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("0.4.5")
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
                
            }
            
            Section {
                HStack {
                    Text("TSIMS for WFLA Int'l")
                        .foregroundStyle(.primary)
                }
                HStack {
                    Text("WFLMS.cn")
                        .foregroundStyle(.primary)
                }                
            } header: {
                Text("Data Sources")
            }
            
            Section {
                Link(destination: URL(string: "mailto:alanye@fastmail.com")!) {
                    Label("Feedbacks & Requests", systemImage: "tray.and.arrow.down")
                        .foregroundStyle(.primary)
                }
                Link(destination: URL(string: "https://object-battle.netlify.app/")!) {
                    Label("Feelin' Lucky", systemImage: "dice")
                        .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("About")
        .contentMargins(.vertical, 10.0)
    }
}

