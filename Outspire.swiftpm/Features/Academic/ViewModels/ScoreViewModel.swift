import SwiftUI
import LocalAuthentication

class ScoreViewModel: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var errorMessage: String?
    @Published var scores: [Score] = []
    @Published var isLoading: Bool = false
    
    private let sessionService = SessionService.shared
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authentication required for requesting sensitive information."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.isUnlocked = true
                        self?.fetchScores()
                    } else {
                        self?.isUnlocked = false
                        if let authError = authenticationError {
                            self?.errorMessage = "Authentication failed: \(authError.localizedDescription)"
                        }
                    }
                }
            }
        } else {
            // No biometrics available, could implement alternative authentication
            isUnlocked = true
            fetchScores()
        }
    }
    
    func fetchScores() {
        // Placeholder when implementing the actual score fetching
        isLoading = true
        errorMessage = nil
        
        // use NetworkService here
        // For now we'll just add a delay to simulate a network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            // Add test data or connect to API
        }
    }
}