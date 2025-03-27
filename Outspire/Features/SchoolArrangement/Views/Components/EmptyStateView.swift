import SwiftUI

struct EmptyStateView: View {
    let searchText: String
    let isAnimated: Bool
    let isSmallScreen: Bool
    let refreshAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Only animate if we're not on a small screen or if this is the first load
            let animationEnabled = !isSmallScreen || AnimationManager.shared.hasAnimated(viewId: "SchoolArrangementView")

            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .opacity(isAnimated ? 1 : 0)
                .scaleEffect(isAnimated ? 1 : 0.8)
                .animation(animationEnabled ? .spring(response: 0.6).delay(0.1) : nil, value: isAnimated)

            Text("No Arrangements Found")
                .font(.title3)
                .fontWeight(.medium)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 10)
                .animation(animationEnabled ? .easeOut.delay(0.2) : nil, value: isAnimated)

            Text(searchText.isEmpty ? "Pull to refresh or tap the refresh button" : "Try changing your search terms")
                .foregroundStyle(.secondary)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 10)
                .animation(animationEnabled ? .easeOut.delay(0.3) : nil, value: isAnimated)

            Button(action: refreshAction) {
                Text("Refresh")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
            }
            .buttonStyle(BorderlessButtonStyle())
            .opacity(isAnimated ? 1 : 0)
            .scaleEffect(isAnimated ? 1 : 0.9)
            .animation(animationEnabled ? .spring(response: 0.6).delay(0.4) : nil, value: isAnimated)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
