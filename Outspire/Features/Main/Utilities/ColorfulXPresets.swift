import SwiftUI
import ColorfulX

// Extension to convert ColorfulPreset to SwiftUI Color array
extension ColorfulPreset {
    var swiftUIColors: [Color] {
        colors.map { Color(uiColor: $0) }
    }
}

// Extension to add these presets to ColorfulX
extension Color {
    // Safely adjust color brightness
    func adjustBrightness(by amount: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // Adjust brightness but keep within valid range
        let newBrightness = max(0, min(1, b + amount))
        
        return Color(UIColor(hue: h, saturation: s, brightness: newBrightness, alpha: a))
    }
}

// Helper extension to ensure gradient colors are properly applied
extension Array where Element == Color {
    func withOpacity(_ opacity: Double) -> [Color] {
        map { $0.opacity(opacity) }
    }
}
