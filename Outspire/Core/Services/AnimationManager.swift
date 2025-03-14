import Foundation
import SwiftUI

class AnimationManager {
    static let shared = AnimationManager()
    
    private init() {}
    
    // Tracking app launch state
    private(set) var isFirstLaunch = true
    
    // Dictionary to track animation states for different views
    private var animatedViews: [String: Bool] = [:]
    
    func markAppLaunched() {
        isFirstLaunch = false
    }
    
    func resetAnimationFlags() {
        // Reset for testing or when signing out
        isFirstLaunch = true
        animatedViews.removeAll()
    }
    
    // Track if a specific view has been animated
    func hasAnimated(viewId: String) -> Bool {
        return animatedViews[viewId] ?? false
    }
    
    // Mark a specific view as animated
    func markAnimated(viewId: String) {
        animatedViews[viewId] = true
    }
    
    // Force a view to animate again
    func resetAnimation(viewId: String) {
        animatedViews[viewId] = false
    }
}

// Extension to help determine device characteristics
extension UIDevice {
    static var isSmallScreen: Bool {
        let screenSize = UIScreen.main.bounds.size
        let smallerDimension = min(screenSize.width, screenSize.height)
        return smallerDimension <= 375 // iPhone SE, iPhone 8 and similar
    }
    
    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
