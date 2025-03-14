import SwiftUI

struct LoadingIndicator: View {
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
                .transition(.opacity.combined(with: .scale))
        }
    }
}

struct RefreshButton: View {
    let isLoading: Bool
    @Binding var rotation: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise")
                .rotationEffect(.degrees(rotation))
                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: rotation)
        }
        .disabled(isLoading)
    }
}
