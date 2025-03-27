import SwiftUI

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 15) {
            ProgressView()

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    LoadingView(message: "Loading data...")
}
