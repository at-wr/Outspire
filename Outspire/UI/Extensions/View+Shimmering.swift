import SwiftUI

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(
                            stops: [
                                .init(color: .clear, location: phase - 0.3),
                                .init(color: .white.opacity(0.2), location: phase),
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
