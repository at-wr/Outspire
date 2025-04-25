import SwiftUI

extension Color {
    /// Adjusts the brightness of a color by the given amount
    /// - Parameters:
    ///   - color: The color to adjust
    ///   - amount: The amount to adjust by (positive = brighter, negative = darker)
    /// - Returns: A new color with adjusted brightness
    static func adjustBrightness(_ color: Color, by amount: CGFloat) -> Color {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return color
        }

        let newBrightness = max(min(b + amount, 1.0), 0.0)
        return Color(UIColor(hue: h, saturation: s, brightness: newBrightness, alpha: a))
    }

    // MARK: - Weather Colors
    static let weatherSun = Color.yellow
    static let weatherCloud = Color.gray
    static let weatherFog = Color.gray.opacity(0.7)
    static let weatherHaze = Color.gray.opacity(0.6)
    static let weatherSmoke = Color.gray.opacity(0.5)
    static let weatherDrizzle = Color.blue.opacity(0.6)
    static let weatherRain = Color.blue
    static let weatherThunderstorm = Color.purple
    static let weatherWind = Color.gray.opacity(0.4)
    static let weatherHail = Color.cyan
    static let weatherSnow = Color.cyan.opacity(0.8)
    static let weatherFreezingDrizzle = Color.blue.opacity(0.5)
    static let weatherFreezingRain = Color.blue.opacity(0.7)
    static let weatherHurricane = Color.indigo
    static let weatherTropicalStorm = Color.teal
}
