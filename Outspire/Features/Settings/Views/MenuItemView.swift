import SwiftUI

struct MenuItemView: View {
    let item: SettingsView.SettingsMenu

    var body: some View {
        switch item {
        case .general:
            Label("General", systemImage: "switch.2")
        case .notifications:
            Label("Notifications", systemImage: "bell")
        case .gradients:
            Label("Gradients", systemImage: "paintpalette")
        case .license:
            Label("Open Source Licenses", systemImage: "doc.text")
        case .about:
            Label("About Outspire", systemImage: "hammer")
        default:
            EmptyView()
        }
    }
}
