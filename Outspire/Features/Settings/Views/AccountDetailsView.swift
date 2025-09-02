import SwiftUI

struct AccountDetailsView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var viewModel = AccountViewModel()

    var body: some View {
        Group {
            AccountV2View()
        }
        .navigationTitle("Account")
    }
}
