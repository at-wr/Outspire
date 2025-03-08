import SwiftUI

struct AccountDetailsView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var viewModel = AccountViewModel()
    
    var body: some View {
        AccountView(viewModel: viewModel)
            .navigationTitle(sessionService.isAuthenticated ? "Account" : "")
            .onAppear {
                if !sessionService.isAuthenticated && viewModel.captchaImageData == nil {
                    viewModel.fetchCaptchaImage()
                }
            }
    }
}

