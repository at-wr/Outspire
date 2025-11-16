import SwiftUI

/// Native Liquid Glass helpers that map directly to Apple’s APIs.
/// References:
/// - Liquid Glass: https://developer.apple.com/documentation/technologyoverviews/liquid-glass/
/// - Applying Liquid Glass: https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views/
public enum GlassmorphicStyle { // kept name to avoid sweeping renames

    /// Standard card style: Liquid Glass on iOS 26+, Material fallback earlier.
    public struct Card: ViewModifier {
        let isDimmed: Bool
        let cornerRadius: CGFloat

        public init(isDimmed: Bool = false, cornerRadius: CGFloat = 16) {
            self.isDimmed = isDimmed
            self.cornerRadius = cornerRadius
        }

        public func body(content: Content) -> some View {
            let shape = RoundedRectangle(cornerRadius: cornerRadius)
            Group {
                if #available(iOS 26.0, *) {
                    content.glassEffect(.regular, in: shape)
                } else {
                    content.background(.ultraThinMaterial, in: shape)
                }
            }
            .opacity(isDimmed ? 0.9 : 1.0)
        }
    }

    /// Card with standard padding.
    public struct PaddedCard: ViewModifier {
        let isDimmed: Bool
        let cornerRadius: CGFloat
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat

        public init(
            isDimmed: Bool = false,
            cornerRadius: CGFloat = 16,
            horizontalPadding: CGFloat = 16,
            verticalPadding: CGFloat = 16
        ) {
            self.isDimmed = isDimmed
            self.cornerRadius = cornerRadius
            self.horizontalPadding = horizontalPadding
            self.verticalPadding = verticalPadding
        }

        public func body(content: Content) -> some View {
            content
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .modifier(Card(isDimmed: isDimmed, cornerRadius: cornerRadius))
        }
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply a Liquid Glass card style.
    func glassmorphicCard(
        isDimmed: Bool = false,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.modifier(GlassmorphicStyle.Card(
            isDimmed: isDimmed,
            cornerRadius: cornerRadius
        ))
    }

    /// Apply a Liquid Glass card style with standard padding.
    func paddedGlassmorphicCard(
        isDimmed: Bool = false,
        cornerRadius: CGFloat = 16,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16
    ) -> some View {
        self.modifier(GlassmorphicStyle.PaddedCard(
            isDimmed: isDimmed,
            cornerRadius: cornerRadius,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding
        ))
    }

    /// Group multiple glass views to blend and morph on iOS 26+, with a simple stack fallback.
    @ViewBuilder
    func glassContainer(spacing: CGFloat = 12) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { self }
        } else {
            VStack(spacing: spacing) { self }
        }
    }
}
