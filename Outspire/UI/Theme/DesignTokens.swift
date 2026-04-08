import SwiftUI

// MARK: - Spacing Tokens

enum AppSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    // Semantic spacing
    static let cardPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 16
}

// MARK: - Radius Tokens

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 18
    static let xl: CGFloat = 22
    static let card: CGFloat = 20
}

// MARK: - Shadow Tokens

enum AppShadow {
    // Crisp edge definition
    static let edgeRadius: CGFloat = 2
    static func edgeOpacity(_ scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.6 : 0.08
    }

    // Soft ambient depth
    static let ambientRadius: CGFloat = 12
    static func ambientOpacity(_ scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.4 : 0.1
    }

    // Elevated card (stronger depth)
    static let elevatedRadius: CGFloat = 16
    static func elevatedOpacity(_ scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.5 : 0.12
    }
}

// MARK: - Color Tokens

enum AppColor {
    static let brand = Color("BrandTint")

    // Rich dark mode surfaces — deep blue-black, not flat gray
    static let richDarkBg = Color(red: 0.06, green: 0.06, blue: 0.09)
    static let richDarkCard = Color(red: 0.10, green: 0.10, blue: 0.14)
    static let richDarkCardSecondary = Color(red: 0.13, green: 0.13, blue: 0.17)
    static let richDarkCardElevated = Color(red: 0.12, green: 0.12, blue: 0.16)
}

// MARK: - Subtle Divider

struct SubtleDivider: View {
    var color: Color = .primary

    var body: some View {
        Rectangle()
            .fill(color.opacity(0.08))
            .frame(height: 0.5)
    }
}

// MARK: - Staggered Entry Animation

extension View {
    func staggeredEntry(index: Int, animate: Bool) -> some View {
        modifier(StaggeredEntryModifier(index: index, animate: animate))
    }
}

private struct StaggeredEntryModifier: ViewModifier {
    let index: Int
    let animate: Bool
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .onAppear {
                guard animate else {
                    appeared = true
                    return
                }
                withAnimation(
                    .spring(response: 0.45, dampingFraction: 0.82)
                        .delay(Double(index) * 0.08)
                ) {
                    appeared = true
                }
            }
    }
}

// MARK: - Scroll Edge Effect (iOS 26+)

extension View {
    /// Applies scroll edge dissolve effect on iOS 26+ for Liquid Glass legibility.
    @ViewBuilder
    func applyScrollEdgeEffect() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}
