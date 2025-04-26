import SwiftUI

struct LoadingView: View {
    let message: String
    var fixedHeight: CGFloat?

    var body: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.5)
                .padding(20)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: fixedHeight)
    }
}

#Preview {
    VStack {
        LoadingView(message: "Loading data...")

        LoadingView(message: "Loading data with fixed height...", fixedHeight: 300)
            .background(Color.gray.opacity(0.1))
    }
}
