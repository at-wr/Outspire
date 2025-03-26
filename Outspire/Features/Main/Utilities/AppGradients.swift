import SwiftUI
import ColorfulX

/// A central place to define app-wide gradient presets for consistency
struct AppGradients {
    // Main view gradients - make them more vibrant
    static let today = ColorfulPreset.sunset.swiftUIColors.map { $0.opacity(0.95) }
    static let classtable = [Color.blue, Color.cyan, Color.green, Color.mint].map { $0.opacity(0.85) } // More vibrant classtable colors
    static let score = ColorfulPreset.sunset.swiftUIColors.map { $0.opacity(0.95) }
    static let clubInfo = [Color.purple, Color.indigo, Color.blue, Color.cyan].map { $0.opacity(0.85) } // More vibrant club colors
    static let clubActivities = [Color.orange, Color.yellow, Color.green, Color.mint].map { $0.opacity(0.85) } // Distinct club activities colors
    static let schoolArrangements = ColorfulPreset.aurora.swiftUIColors.map { $0.opacity(0.95) }
    static let lunchMenu = [Color.orange, Color.yellow, Color.red, Color.purple].map { $0.opacity(0.85) }
    static let map = ColorfulPreset.ocean.swiftUIColors.map { $0.opacity(0.95) }
    
    // Special state gradients
    static let notSignedIn = ColorfulPreset.ocean.swiftUIColors.map { $0.opacity(0.95) }
    static let weekend = ColorfulPreset.sunset.swiftUIColors.map { $0.opacity(0.95) }
    static let holiday = ColorfulPreset.sunset.swiftUIColors.map { $0.opacity(0.95) }
    
    // Default fallback gradient
    static let defaultGradient = ColorfulPreset.aurora.swiftUIColors.map { $0.opacity(0.95) }
}

extension GradientManager {
    /// Updates the gradient to the appropriate preset for the given view type
    func updateGradientForView(_ viewType: ViewType, colorScheme: ColorScheme) {
        // Increase noise for more texture and visibility
        let noise: Double = colorScheme == .dark ? 25.0 : 30.0
        
        switch viewType {
        case .today:
            updateGradient(colors: AppGradients.today, speed: 0.6, noise: noise)
        case .classtable:
            updateGradient(colors: AppGradients.classtable, speed: 0.5, noise: noise)
        case .score:
            updateGradient(colors: AppGradients.score, speed: 0.5, noise: noise)
        case .clubInfo:
            updateGradient(colors: AppGradients.clubInfo, speed: 0.5, noise: noise)
        case .clubActivities:
            updateGradient(colors: AppGradients.clubActivities, speed: 0.5, noise: noise)
        case .schoolArrangements:
            updateGradient(colors: AppGradients.schoolArrangements, speed: 0.4, noise: noise)
        case .lunchMenu:
            updateGradient(colors: AppGradients.lunchMenu, speed: 0.4, noise: noise)
        case .map:
            updateGradient(colors: AppGradients.map, speed: 0.5, noise: noise)
        case .notSignedIn:
            updateGradient(colors: AppGradients.notSignedIn, speed: 0.6, noise: noise)
        case .weekend:
            updateGradient(colors: AppGradients.weekend, speed: 0.5, noise: noise)
        case .holiday:
            updateGradient(colors: AppGradients.holiday, speed: 0.4, noise: noise)
        }
    }
    
    /// Updates the gradient based on the current application context
    func updateGradientForContext(
        isAuthenticated: Bool,
        isHolidayMode: Bool,
        isWeekend: Bool,
        upcomingClass: (classData: String, isActive: Bool)? = nil,
        colorScheme: ColorScheme
    ) {
        let noise: Double = colorScheme == .dark ? 15.0 : 20.0
        
        if isHolidayMode {
            updateGradientForView(.holiday, colorScheme: colorScheme)
        } else if isWeekend {
            updateGradientForView(.weekend, colorScheme: colorScheme)
        } else if !isAuthenticated {
            updateGradientForView(.notSignedIn, colorScheme: colorScheme)
        } else if let (classData, isActive) = upcomingClass {
            // Class-specific gradient
            let components = classData.replacingOccurrences(of: "<br>", with: "\n")
                .components(separatedBy: "\n")
                .filter { !$0.isEmpty }
            
            if components.count > 1 {
                let subjectColor = ClasstableView.getSubjectColor(from: components[1])
                let darkerVariant = subjectColor.adjustBrightness(by: -0.2)
                let lighterVariant = subjectColor.adjustBrightness(by: 0.2)
                
                let colors = [
                    Color.white,
                    lighterVariant,
                    subjectColor,
                    darkerVariant
                ]
                
                updateGradient(colors: colors, speed: isActive ? 0.7 : 0.5, noise: noise)
            } else {
                updateGradient(colors: AppGradients.defaultGradient, speed: 0.5, noise: noise)
            }
        } else {
            updateGradient(colors: AppGradients.defaultGradient, speed: 0.5, noise: noise)
        }
    }
}

/// Enum defining the different view types in the app for gradient selection
enum ViewType {
    case today
    case classtable
    case score
    case clubInfo
    case clubActivities
    case schoolArrangements
    case lunchMenu
    case map
    case notSignedIn
    case weekend
    case holiday
}
