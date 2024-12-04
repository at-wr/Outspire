import SwiftUI
import LocalAuthentication

// Still a WIP
struct ScoreView: View {
    @State private var isUnlocked = false
    var body: some View {
        VStack {
            if isUnlocked {
                Text("Unlocked")
            } else {
                Text("Locked")
            }
        }
        .onAppear(perform: {
            authenticate()
        })
    }
    
    func authenticate() {
        // thanks to hackingwithswift.com ww
        let context = LAContext()
        var error: NSError?
        
        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "Authentication required for requesting sensitive information."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    // authenticated successfully
                    isUnlocked = true
                } else {
                    // there was a problem
                    isUnlocked = false
                }
            }
        } else {
            // no biometrics
            isUnlocked = true
        }
    }
}

#Preview {
    ScoreView()
}
