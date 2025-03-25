import SwiftUI
import ColorfulX

class GradientManager: ObservableObject {
    @Published var gradientColors: [Color] = ColorfulPreset.aurora.swiftUIColors
    @Published var gradientSpeed: Double = 0.5 // Medium speed for animation
    @Published var gradientNoise: Double = 20.0 // Moderate noise level
    @Published var gradientTransitionSpeed: Double = 1.0 // Standard transition speed
    
    // Method to update the gradient settings
    func updateGradient(
        colors: [Color]? = nil,
        speed: Double? = nil,
        noise: Double? = nil,
        transitionSpeed: Double? = nil
    ) {
        if let colors = colors {
            gradientColors = colors
        }
        if let speed = speed {
            gradientSpeed = speed
        }
        if let noise = noise {
            gradientNoise = noise
        }
        if let transitionSpeed = transitionSpeed {
            gradientTransitionSpeed = transitionSpeed
        }
    }
    
    // Helper method to create a gradient based on context
    func updateGradientForContext(
        isAuthenticated: Bool,
        isHolidayMode: Bool,
        isWeekend: Bool,
        upcomingClass: (classData: String, isActive: Bool)? = nil,
        colorScheme: ColorScheme
    ) {
        var colors: [Color]
        var speed: Double
        let noise: Double = colorScheme == .dark ? 15.0 : 20.0  // Reduce noise in dark mode for subtler effect
        
        if isHolidayMode {
            // Holiday mode gradient
            colors = ColorfulPreset.sunset.swiftUIColors
            speed = 0.3
        } else if isWeekend {
            // Weekend gradient
            colors = ColorfulPreset.sunset.swiftUIColors
            speed = 0.4
        } else if !isAuthenticated {
            // Not signed in gradient
            colors = ColorfulPreset.ocean.swiftUIColors
            speed = 0.5
        } else if let (classData, isActive) = upcomingClass {
            // Class-specific gradient
            let components = classData.replacingOccurrences(of: "<br>", with: "\n")
                .components(separatedBy: "\n")
                .filter { !$0.isEmpty }
            
            if components.count > 1 {
                let subjectColor = ClasstableView.getSubjectColor(from: components[1])
                let darkerVariant = subjectColor.adjustBrightness(by: -0.2)
                let lighterVariant = subjectColor.adjustBrightness(by: 0.2)
                
                colors = [
                    Color.white,
                    lighterVariant,
                    subjectColor,
                    darkerVariant
                ]
                
                speed = isActive ? 0.7 : 0.5
            } else {
                colors = ColorfulPreset.aurora.swiftUIColors
                speed = 0.5
            }
        } else {
            // Default gradient
            colors = ColorfulPreset.sunset.swiftUIColors
            speed = 0.5
        }
        
        updateGradient(colors: colors, speed: speed, noise: noise)
    }
}
