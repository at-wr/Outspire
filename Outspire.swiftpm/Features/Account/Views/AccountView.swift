import SwiftUI

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        SwiftUI.Group {
            if viewModel.isAuthenticated {
                loggedInView
            } else {
                loginView
            }
        }
        .onAppear {
            if viewModel.captchaImageData == nil && !viewModel.isAuthenticated {
                viewModel.fetchCaptchaImage()
            }
        }
    }
    
    var loginView: some View {
        Form {
            Section {
                TextField("Username", text: $viewModel.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $viewModel.password)
                
                HStack {
                    TextField("CAPTCHA", text: $viewModel.captcha)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if viewModel.isCaptchaLoading {
                        ProgressView()
                    } else if let data = viewModel.captchaImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 75, height: 30)
                            .cornerRadius(5)
                    }
                }
                
                Button(action: viewModel.login) {
                    Text("Sign In")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            } footer: {
                let connectionStatus = Configuration.useSSL ? 
                    "Your connection has been encrypted." : 
                    "Your connection hasn't been encrypted.\nRelay Encryption is recommended if you're using a public network."
                Text("All data will only be stored on this device and the TSIMS server. \n\(connectionStatus)")
                    .font(.caption)
            }
        }
        .navigationTitle("Sign In")
        .toolbar {
            Button(action: viewModel.fetchCaptchaImage) {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
        }
    }
    
    var loggedInView: some View {
        Form {
            if let userInfo = viewModel.userInfo {
                Section {
                    LabeledContent("No.", value: userInfo.tUsername)
                    LabeledContent("ID", value: userInfo.studentid)
                    LabeledContent("Name", value: "\(userInfo.studentname) \(userInfo.nickname)")
                    
                    Button(action: { showLogoutConfirmation.toggle() }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
                .confirmationDialog(
                    "Sign Out",
                    isPresented: $showLogoutConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Sign Out", role: .destructive, action: viewModel.logout)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to sign out?")
                }
            }
        }
        .navigationTitle("Account Details")
    }
}