import SwiftUI

/// A collection of modifiers and components for creating consistent glassmorphic UI elements
/// that follow Apple's Human Interface Guidelines for depth, materials, and visual hierarchy.
public enum GlassmorphicStyle {
    
    /// Standard card style with subtle border and background
    public struct Card: ViewModifier {
        let isDimmed: Bool
        let cornerRadius: CGFloat
        
        @Environment(\.colorScheme) private var colorScheme
        
        public init(isDimmed: Bool = false, cornerRadius: CGFloat = 16) {
            self.isDimmed = isDimmed
            self.cornerRadius = cornerRadius
        }
        
        public func body(content: Content) -> some View {
            content
                .background(
                    ZStack {
                        // Base blur layer using Apple's material system
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(colorScheme == .dark ? 0.8 : 0.92)
                        
                        // Subtle gradient overlay for depth
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.3),
                                        Color.white.opacity(colorScheme == .dark ? 0.02 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(isDimmed ? 0.5 : 1.0)
                        
                        // Subtle border for definition
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.5),
                                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                            .opacity(isDimmed ? 0.5 : 1.0)
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.08),
                        radius: 15,
                        x: 0,
                        y: 5
                    )
                )
                .opacity(isDimmed ? 0.85 : 1.0)
        }
    }
    
    /// A modifier for creating a card with standard padding
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
    /// Apply a glassmorphic card style to a view.
    func glassmorphicCard(
        isDimmed: Bool = false, 
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.modifier(GlassmorphicStyle.Card(
            isDimmed: isDimmed,
            cornerRadius: cornerRadius
        ))
    }
    
    /// Apply a glassmorphic card style with standard padding.
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
}
