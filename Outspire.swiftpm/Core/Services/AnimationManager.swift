import Foundation

class AnimationManager {
    static let shared = AnimationManager()
    
    private init() {}
    
    // Tracking app launch state
    private(set) var isFirstLaunch = true
    
    func markAppLaunched() {
        isFirstLaunch = false
    }
    
    func resetAnimationFlags() {
        // Reset for testing or when signing out
        isFirstLaunch = true
    }
}
