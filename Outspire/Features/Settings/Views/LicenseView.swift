import SwiftUI

struct LicenseView: View {
    @State private var licenseText: String = "Loading Licenses..."

    private func loadLicenses() {
        if let url = Bundle.main.url(forResource: "ThirdPartyLicenses", withExtension: "txt"),
           let content = try? String(contentsOf: url)
        {
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
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Open Source Licenses")
        .onAppear(perform: loadLicenses)
    }
}

#Preview {
    LicenseView()
}
