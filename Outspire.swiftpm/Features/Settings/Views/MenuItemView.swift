import SwiftUI

struct MenuItemView: View {
    let item: SettingsView.SettingsMenu
    
    var body: some View {
        switch item {
        case .general:
            Label("General", systemImage: "switch.2")
        case .export:
            Label("Export App Package", systemImage: "shippingbox")
        case .license:
            Label("Open Source Licenses", systemImage: "doc.text")
        default:
            EmptyView()
        }
    }
}
