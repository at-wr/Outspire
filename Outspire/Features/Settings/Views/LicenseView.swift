import SwiftUI

struct LicenseView: View {
    @State private var licenseText: String = "Loading Licenses..."

    private func loadLicenses() {
        if let url = Bundle.main.url(forResource: "ThirdPartyLicenses", withExtension: "txt"),
           let content = try? String(contentsOf: url) {
            licenseText = content
        } else {
            licenseText = "License currently unavailable."
        }
    }

    var body: some View {
        ScrollView {
            Text(licenseText)
                .padding()
                .font(.system(size: 14))
                .fontDesign(.monospaced)
                .backgroundStyle(Color(UIColor.secondarySystemFill))
        }
        .scrollIndicators(.hidden)
        .backgroundStyle(Color(UIColor.secondarySystemFill))
        .navigationTitle("Open Source Licenses")
        .toolbarBackground(Color(UIColor.secondarySystemBackground))
        .onAppear(perform: loadLicenses)
    }
}

#Preview {
    LicenseView()
}
