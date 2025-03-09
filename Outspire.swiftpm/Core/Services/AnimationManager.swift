import Foundation

class AnimationManager {
    static let shared = AnimationManager()
    
    private init() {}
    
    // Flags to track animations across app
    private(set) var hasShownTodayViewAnimation = false
    
    func markTodayViewAnimationShown() {
        hasShownTodayViewAnimation = true
    }
    
    func resetAnimationFlags() {
        // Call this when you want to reset animations (like app launch or signout)
        hasShownTodayViewAnimation = false
    }
}