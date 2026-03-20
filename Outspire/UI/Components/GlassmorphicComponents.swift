import SwiftUI

/// Card style system: Liquid Glass on iOS 26+, rich skeuomorphic depth everywhere.
public enum GlassmorphicStyle {
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

    /// Rich elevated card — Liquid Glass on iOS 26+, dual-layer shadow + top highlight on earlier.
    public struct RichCard: ViewModifier {
        let cornerRadius: CGFloat
        let shadowRadius: CGFloat

        @Environment(\.colorScheme) private var colorScheme

        public init(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 12) {
            self.cornerRadius = cornerRadius
            self.shadowRadius = shadowRadius
        }

        public func body(content: Content) -> some View {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            if #available(iOS 26.0, *) {
                content
                    .glassEffect(.regular, in: shape)
            } else {
                content
                    .clipShape(shape)
                    .background(
                        shape
                            .fill(colorScheme == .dark
                                ? AppColor.richDarkCard
                                : Color(.systemBackground))
                            // Top-edge highlight for glass-like definition
                            .overlay(
                                shape
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(colorScheme == .dark ? 0.12 : 0.5),
                                                .white.opacity(colorScheme == .dark ? 0.03 : 0.08),
                                                .clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 0.75
                                    )
                            )
                            // Tight inner-ish shadow for crisp edge
                            .shadow(
                                color: .black.opacity(AppShadow.edgeOpacity(colorScheme)),
                                radius: AppShadow.edgeRadius,
                                x: 0,
                                y: 1
                            )
                            // Wide soft shadow for depth
                            .shadow(
                                color: .black.opacity(AppShadow.ambientOpacity(colorScheme)),
                                radius: shadowRadius,
                                x: 0,
                                y: shadowRadius / 2
                            )
                    )
            }
        }
    }

    /// Elevated card — tinted background with stronger depth for high-emphasis content.
    public struct ElevatedCard: ViewModifier {
        let accentColor: Color
        let cornerRadius: CGFloat

        @Environment(\.colorScheme) private var colorScheme

        public init(accentColor: Color = .blue, cornerRadius: CGFloat = 20) {
            self.accentColor = accentColor
            self.cornerRadius = cornerRadius
        }

        public func body(content: Content) -> some View {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            if #available(iOS 26.0, *) {
                content
                    .tint(accentColor)
                    .glassEffect(.regular, in: shape)
            } else {
                content
                    .clipShape(shape)
                    .background(
                        shape
                            .fill(colorScheme == .dark
                                ? AppColor.richDarkCardElevated
                                : Color(.systemBackground))
                            // Tinted overlay — visible color wash
                            .overlay(
                                shape.fill(
                                    LinearGradient(
                                        colors: [
                                            accentColor.opacity(colorScheme == .dark ? 0.12 : 0.06),
                                            accentColor.opacity(colorScheme == .dark ? 0.04 : 0.02)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                            // Top-edge highlight — pronounced glass edge
                            .overlay(
                                shape
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(colorScheme == .dark ? 0.15 : 0.6),
                                                .white.opacity(colorScheme == .dark ? 0.04 : 0.1),
                                                .clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            // Crisp edge shadow
                            .shadow(
                                color: .black.opacity(AppShadow.edgeOpacity(colorScheme)),
                                radius: AppShadow.edgeRadius,
                                x: 0,
                                y: 1
                            )
                            // Strong ambient shadow
                            .shadow(
                                color: .black.opacity(colorScheme == .dark ? 0.6 : 0.14),
                                radius: 20,
                                x: 0,
                                y: 10
                            )
                            // Colored glow — prominent
                            .shadow(
                                color: accentColor.opacity(colorScheme == .dark ? 0.25 : 0.12),
                                radius: 24,
                                x: 0,
                                y: 12
                            )
                    )
            }
        }
    }

    /// Colored rich card — gradient fill with dual-layer shadow.
    public struct ColoredRichCard: ViewModifier {
        let colors: [Color]
        let cornerRadius: CGFloat
        let shadowRadius: CGFloat

        @Environment(\.colorScheme) private var colorScheme

        public init(colors: [Color], cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 12) {
            self.colors = colors
            self.cornerRadius = cornerRadius
            self.shadowRadius = shadowRadius
        }

        public func body(content: Content) -> some View {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            content
                .background(
                    shape.fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    // Subtle inner highlight at top
                    .overlay(
                        shape
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                ),
                                lineWidth: 0.5
                            )
                    )
                )
                .clipShape(shape)
                // Tight edge shadow
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.5 : 0.06),
                    radius: AppShadow.edgeRadius,
                    x: 0,
                    y: 1
                )
                // Wide color glow
                .shadow(
                    color: colors.first?.opacity(colorScheme == .dark ? 0.35 : 0.22) ?? .clear,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowRadius / 2
                )
        }
    }
}

// MARK: - View Extensions

public extension View {
    func glassmorphicCard(
        isDimmed: Bool = false,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.modifier(GlassmorphicStyle.Card(isDimmed: isDimmed, cornerRadius: cornerRadius))
    }

    func paddedGlassmorphicCard(
        isDimmed: Bool = false,
        cornerRadius: CGFloat = 16,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16
    ) -> some View {
        self.modifier(GlassmorphicStyle.PaddedCard(
            isDimmed: isDimmed, cornerRadius: cornerRadius,
            horizontalPadding: horizontalPadding, verticalPadding: verticalPadding
        ))
    }

    func richCard(
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 12
    ) -> some View {
        self.modifier(GlassmorphicStyle.RichCard(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }

    func elevatedCard(
        accentColor: Color = .blue,
        cornerRadius: CGFloat = 20
    ) -> some View {
        self.modifier(GlassmorphicStyle.ElevatedCard(accentColor: accentColor, cornerRadius: cornerRadius))
    }

    func coloredRichCard(
        colors: [Color],
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 12
    ) -> some View {
        self.modifier(GlassmorphicStyle.ColoredRichCard(
            colors: colors, cornerRadius: cornerRadius, shadowRadius: shadowRadius
        ))
    }

    @ViewBuilder
    func glassContainer(spacing: CGFloat = 12) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { self }
        } else {
            VStack(spacing: spacing) { self }
        }
    }
}
