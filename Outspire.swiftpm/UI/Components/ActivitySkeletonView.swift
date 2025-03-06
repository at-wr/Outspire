import SwiftUI

struct ActivitySkeletonView: View {
    var body: some View {
        VStack(spacing: 15) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    // Title
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .frame(width: 200)
                    
                    // Date
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 14)
                        .frame(width: 120)
                    
                    // CAS Badges
                    HStack {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 24)
                        }
                    }
                    
                    // Reflection
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 10)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 10)
            }
        }
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// Shimmer effect
extension View {
    @ViewBuilder
    func shimmering() -> some View {
        self.modifier(ShimmerEffect())
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0),
                            .init(color: Color.white.opacity(0.7), location: 0.4),
                            .init(color: Color.clear, location: 0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 3)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 3))
                    .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
                    .mask(content)
                    .onAppear {
                        phase = 1
                    }
                }
            )
    }
}