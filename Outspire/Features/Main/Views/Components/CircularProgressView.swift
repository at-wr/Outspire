import SwiftUI

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
