import SwiftUI

/// Rich background modifier: warm tint in light mode, deep blue-black in dark mode.
struct AppBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(backgroundColor, ignoresSafeAreaEdges: .all)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? AppColor.richDarkBg : Color(.systemGroupedBackground)
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }
}
