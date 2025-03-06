import SwiftUI

struct AccountDetailsView: View {
    @EnvironmentObject var sessionService: SessionService
    
    var body: some View {
        AccountView()
    }
}

#Preview {
    AccountDetailsView()
        .environmentObject(SessionService.shared)
}