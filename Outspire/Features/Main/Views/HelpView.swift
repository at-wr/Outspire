import SwiftUI
// Removed ColorfulX usage in favor of system materials
import QuickLook

struct HelpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var gradientManager: GradientManager
    @State private var previewURL: URL?
    @State private var showPreview = false

    var body: some View {
        // Main help content, rely on system background
        VStack {
        }
        .navigationTitle("Help & About")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPreview) {
            if previewURL != nil {
                // Intentionally left empty for now; replace with QuickLookPreview when implemented.
            }
        }
        .onAppear {
            updateGradientForHelpView()
        }
    }

    private func updateGradientForHelpView() {
        // No-op for backgrounds; retain default system appearance
    }

}

#Preview {
    HelpView()
        .environmentObject(GradientManager())
}
