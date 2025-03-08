import SwiftUI
import Toasts

struct AccountView: View {
    @Environment(\.presentToast) var presentToast
    @StateObject private var viewModel = AccountViewModel()
    @State private var showLogoutConfirmation = false
    @State private var refreshButtonRotation = 0.0
    
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
        .onChange(of: viewModel.errorMessage) { errorMessage in  // Observe errorMessage
            if let errorMessage = errorMessage {
                let toast = ToastValue(
                    icon: Image(systemName: "exclamationmark.triangle").foregroundColor(.red),
                    message: errorMessage
                )
                presentToast(toast)
                // Optionally clear the error message after displaying the toast
                viewModel.errorMessage = nil  // Clear the error after displaying
            }
        }
        .onChange(of: viewModel.successMessage) { successMessage in  // Observe errorMessage
            if let successMessage = successMessage {
                let toast = ToastValue(
                    icon: Image(systemName: "checkmark.circle").foregroundColor(.green),
                    message: successMessage
                )
                presentToast(toast)
                viewModel.successMessage = nil
            }
        }
    }
    
    var loginView: some View {
        VStack {
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
                    
                    /*
                     if let errorMessage = viewModel.errorMessage {
                     Text(errorMessage)
                     .foregroundColor(.red)
                     }
                     */
                } footer: {
                    let connectionStatus = Configuration.useSSL ?
                    "Your connection has been encrypted." :
                    "Your connection hasn't been encrypted.\nRelay Encryption is recommended if you're using a public network."
                    Text("All data will only be stored on this device and the TSIMS server. \n\(connectionStatus)")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Sign In")
        .toolbar {
            refreshButton
        }
    }
    
    var loggedInView: some View {
        Form {
            if let userInfo = viewModel.userInfo {
                Section {
                    LabeledContent("Username", value: userInfo.tUsername)
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
    
    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                withAnimation {
                    refreshButtonRotation += 360
                }
                viewModel.fetchCaptchaImage()
            }) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(refreshButtonRotation))
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: refreshButtonRotation)
                    .disabled(!viewModel.canRefreshCaptcha) // Disable the button
                    .opacity(viewModel.canRefreshCaptcha ? 1.0 : 0.5) // Visually indicate disabled state
            }
        }
    }
}
