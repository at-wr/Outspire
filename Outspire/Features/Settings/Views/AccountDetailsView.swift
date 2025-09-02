import SwiftUI

struct AccountDetailsView: View {
    @EnvironmentObject var sessionService: SessionService
    // Legacy AccountViewModel removed; V2 view is used exclusively

    var body: some View {
        Group {
            AccountV2View()
        }
        .navigationTitle("Account")
    }
}
