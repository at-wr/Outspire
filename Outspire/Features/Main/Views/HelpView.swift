import SwiftUI
import ColorfulX
import QuickLook

struct HelpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var gradientManager: GradientManager
    @State private var previewURL: URL?
    @State private var showPreview = false

    var body: some View {
        ZStack {
            ColorfulView(
                color: $gradientManager.gradientColors,
                speed: $gradientManager.gradientSpeed,
                noise: $gradientManager.gradientNoise,
                transitionSpeed: $gradientManager.gradientTransitionSpeed
            )
            .ignoresSafeArea()
            .opacity(colorScheme == .dark ? 0.15 : 0.3)

            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7)
                .ignoresSafeArea()

            // Main help content
            VStack {
            }
        }
        .navigationTitle("Help & About")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPreview) {
            if let url = previewURL {
            }
        }
        .onAppear {
            updateGradientForHelpView()
        }
    }

    private func updateGradientForHelpView() {
        gradientManager.updateGradient(
            colors: ColorfulPreset.ocean.swiftUIColors,
            speed: 0.3,
            noise: colorScheme == .dark ? 15.0 : 20.0
        )
    }

}

#Preview {
    HelpView()
        .environmentObject(GradientManager())
}
