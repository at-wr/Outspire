import UIKit

/// A centralized manager for providing consistent haptic feedback throughout the app
final class HapticManager {
    /// Shared instance for global access
    static let shared = HapticManager()

    private init() {}

    /// Play impact feedback with the specified intensity
    /// - Parameter style: The intensity of the haptic feedback
    func playFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Play light impact feedback for subtle interactions
    func playLightFeedback() {
        playFeedback(.light)
    }

    /// Play medium impact feedback for standard interactions
    func playMediumFeedback() {
        playFeedback(.medium)
    }

    /// Play heavy impact feedback for important interactions
    func playHeavyFeedback() {
        playFeedback(.heavy)
    }

    /// Play notification feedback for system events
    /// - Parameter type: The type of notification feedback
    func playNotificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Play success notification feedback
    func playSuccessFeedback() {
        playNotificationFeedback(.success)
    }

    /// Play warning notification feedback
    func playWarningFeedback() {
        playNotificationFeedback(.warning)
    }

    /// Play error notification feedback
    func playErrorFeedback() {
        playNotificationFeedback(.error)
    }

    /// Play selection feedback for picker changes
    func playSelectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Convenience Extensions

extension HapticManager {
    /// Haptic feedback for successful save operations
    func playSuccessfulSave() {
        playSuccessFeedback()
    }

    /// Haptic feedback for delete operations
    func playDelete() {
        playNotificationFeedback(.warning)
    }

    /// Haptic feedback for form submission
    func playFormSubmission() {
        playMediumFeedback()
    }

    /// Haptic feedback for refresh actions
    func playRefresh() {
        playMediumFeedback()
    }

    /// Haptic feedback for toggle switches
    func playToggle() {
        playLightFeedback()
    }

    /// Haptic feedback for button taps
    func playButtonTap() {
        playLightFeedback()
    }

    /// Haptic feedback for navigation actions
    func playNavigation() {
        playLightFeedback()
    }

    /// Haptic feedback for errors
    func playError() {
        playErrorFeedback()
    }

    /// Haptic feedback for stepper value changes
    func playStepperChange() {
        playLightFeedback()
    }
}
