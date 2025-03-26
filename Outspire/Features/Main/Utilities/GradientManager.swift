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
    
    // Remove the duplicate updateGradientForContext method from here
    // as it's now moved to AppGradients.swift extension
    
    // Helper methods can stay
}
