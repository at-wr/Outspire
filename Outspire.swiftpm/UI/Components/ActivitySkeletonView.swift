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
        // .shimmering()
    }
}

// Shimmer effect
extension View {
    func shimmer() -> some View {
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
                        gradient: Gradient(
                            stops: [
                                .init(color: .clear, location: phase - 0.3),
                                .init(color: .white.opacity(0.3), location: phase),
                                .init(color: .clear, location: phase + 0.3)
                            ]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(content)
                    .blendMode(.screen)
                    .offset(x: -geometry.size.width + (2 * geometry.size.width * phase))
                }
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    self.phase = 1
                }
            }
    }
}
