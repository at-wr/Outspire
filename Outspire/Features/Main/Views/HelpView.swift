import SwiftUI
#if !targetEnvironment(macCatalyst)
import ColorfulX
#endif
import QuickLook

struct HelpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var gradientManager: GradientManager
    @State private var previewURL: URL?
    @State private var showPreview = false

    var body: some View {
        ZStack {
            #if !targetEnvironment(macCatalyst)
            ColorfulView(
                color: $gradientManager.gradientColors,
                speed: $gradientManager.gradientSpeed,
                noise: $gradientManager.gradientNoise,
                transitionSpeed: $gradientManager.gradientTransitionSpeed
            )
            .ignoresSafeArea()
            .opacity(colorScheme == .dark ? 0.15 : 0.3)
            #else
            Color(.systemBackground)
                .ignoresSafeArea()
            #endif

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
        #if !targetEnvironment(macCatalyst)
        gradientManager.updateGradient(
            colors: ColorfulPreset.ocean.swiftUIColors,
            speed: 0.3,
            noise: colorScheme == .dark ? 15.0 : 20.0
        )
        #else
        gradientManager.updateGradient(
            colors: [Color(.systemBackground)],
            speed: 0.0,
            noise: 0.0
        )
        #endif
    }

}

#Preview {
    HelpView()
        .environmentObject(GradientManager())
}
