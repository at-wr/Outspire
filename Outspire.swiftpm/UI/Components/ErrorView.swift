import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    var retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
                .padding(.top, 4)
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .padding(.top)
            }
        }
        .padding()
    }
}

#Preview {
    ErrorView(errorMessage: "Something went wrong", retryAction: {})
}