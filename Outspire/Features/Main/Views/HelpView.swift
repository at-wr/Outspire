import SwiftUI
import ColorfulX
import QuickLook

struct HelpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var gradientManager: GradientManager // Add gradient manager
    @State private var previewURL: URL?
    @State private var showPreview = false
    
    var body: some View {
        ZStack {
            // Add ColorfulX as background
            ColorfulView(
                color: $gradientManager.gradientColors,
                speed: $gradientManager.gradientSpeed,
                noise: $gradientManager.gradientNoise,
                transitionSpeed: $gradientManager.gradientTransitionSpeed
            )
            .ignoresSafeArea()
            .opacity(colorScheme == .dark ? 0.15 : 0.3) // Reduce opacity more in dark mode
            
            // Semi-transparent background for better contrast
            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7)
                .ignoresSafeArea()
            
            // Main help content
            VStack {
                // ...existing help content...
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
    
    // Add method to update gradient for help view
    private func updateGradientForHelpView() {
        gradientManager.updateGradient(
            colors: ColorfulPreset.ocean.swiftUIColors,
            speed: 0.3,
            noise: colorScheme == .dark ? 15.0 : 20.0
        )
    }
    
    // ...existing code...
}

#Preview {
    HelpView()
        .environmentObject(GradientManager())
}
