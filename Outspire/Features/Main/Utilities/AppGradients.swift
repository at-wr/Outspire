import SwiftUI
import ColorfulX

/// A central place to define app-wide gradient presets for consistency
struct AppGradients {
    // Context-specific gradients (these take priority)
    static let inClass = ColorfulPreset.ocean.swiftUIColors
    static let upcomingClass = ColorfulPreset.aurora.swiftUIColors
    static let selfStudy = ColorfulPreset.lavandula.swiftUIColors
    static let upcomingSelfStudy = ColorfulPreset.lavandula.swiftUIColors.map { $0.opacity(0.8) }
    static let afterSchool = ColorfulPreset.sunset.swiftUIColors

    // State gradients
    static let notSignedIn = ColorfulPreset.winter.swiftUIColors
    static let weekend = ColorfulPreset.sunrise.swiftUIColors
    static let holiday = ColorfulPreset.autumn.swiftUIColors

    // Default fallback gradient
    static let defaultGradient = ColorfulPreset.aurora.swiftUIColors
}
