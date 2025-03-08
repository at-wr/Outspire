import SwiftUI
import Toasts

struct AccountView: View {
    @Environment(\.presentToast) var presentToast
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: AccountViewModel
    @State private var showLogoutConfirmation = false
    @State private var refreshButtonRotation = 0.0
    @State private var isTransitioning = false
    @FocusState private var focusedField: FormField?
    
    init(viewModel: AccountViewModel? = nil) {
        _viewModel = ObservedObject(wrappedValue: viewModel ?? AccountViewModel())
    }
    
    enum FormField {
        case username, password, captcha
    }
    
    var body: some View {
        Group {
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
        .onChange(of: viewModel.errorMessage) { _, errorMessage in
            handleMessage(errorMessage, isError: true)
        }
        .onChange(of: viewModel.successMessage) { _, successMessage in
            handleMessage(successMessage, isError: false)
        }
        .id(viewModel.isAuthenticated)
    }
    
    private var loginView: some View {
        VStack(spacing: 0) {
            // Header with icon
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 72))
                    .foregroundStyle(.gray)
                    .symbolRenderingMode(.hierarchical)
                    .padding(.top, 30)
            }
            .padding(.bottom, 30)
            
            // Form fields
            VStack(spacing: 20) {
                TextField("Username", text: $viewModel.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    .padding(.vertical, 12)
                    .background(
                        VStack {
                            Spacer()
                            Divider()
                        }
                    )
                
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .captcha }
                    .padding(.vertical, 12)
                    .background(
                        VStack {
                            Spacer()
                            Divider()
                        }
                    )
                
                // CAPTCHA field and image
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        TextField("CAPTCHA", text: $viewModel.captcha)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .captcha)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = nil
                                login()
                            }
                            .padding(.vertical, 12)
                            .background(
                                VStack {
                                    Spacer()
                                    Divider()
                                }
                            )
                        
                        if viewModel.isRecognizingCaptcha {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Auto-recognizing...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    // CAPTCHA image
                    captchaImageView
                        .frame(width: 90, height: 36)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Sign In button outside form
            Button(action: login) {
                ZStack {
                    if viewModel.isLoggingIn || viewModel.isAutoRetrying {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                )
            }
            .disabled(viewModel.isLoggingIn)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            
            // Footer text
            Text("Tap the CAPTCHA image to refresh. All data will only be stored on this device and the TSIMS server.")
                .font(.caption)
                .foregroundStyle(.secondary)
                //.multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            
            let connectionStatus = Configuration.useSSL ?
            "Your connection has been encrypted." :
            "Relay Encryption is recommended if you're using a public network."
            
            Text(connectionStatus)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .toolbar {
            refreshButtonItem
        }
        .scrollDismissesKeyboard(.immediately)
        .onChange(of: viewModel.isAuthenticated) { _, newValue in
            if newValue {
                withAnimation { isTransitioning = true }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { isTransitioning = false }
                    NotificationCenter.default.post(name: .authenticationStatusChanged, object: nil)
                }
            }
        }
    }
    
    private var loggedInView: some View {
        Form {
            // User information
            Section("Account Information") {
                if let userInfo = viewModel.userInfo {
                    LabeledContent("Name", value: "\(userInfo.studentname ?? "") (\(userInfo.nickname ?? ""))")
                    LabeledContent("Student ID", value: userInfo.studentid)
                    LabeledContent("Student No", value: userInfo.studentNo)
                }
            }
            
            // Sign out
            Section {
                Button("Sign Out", role: .destructive) {
                    showLogoutConfirmation = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.secondarySystemBackground))
        .navigationTitle("Account")
        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                viewModel.logout()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var captchaImageView: some View {
        Group {
            if viewModel.isCaptchaLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let data = viewModel.captchaImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { refreshCaptcha() }
            } else {
                Text("Loading...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { viewModel.fetchCaptchaImage() }
            }
        }
    }
    
    private var refreshButtonItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: refreshCaptcha) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(refreshButtonRotation))
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: refreshButtonRotation)
            }
        }
    }
    
    private func refreshCaptcha() {
        withAnimation { refreshButtonRotation += 360 }
        viewModel.fetchCaptchaImage()
        playImpactFeedback(.light)
    }
    
    private func login() {
        focusedField = nil
        viewModel.login()
        playImpactFeedback(.medium)
    }
    
    private func handleMessage(_ message: String?, isError: Bool) {
        guard let message = message else { return }
        
        let icon = isError ? 
        Image(systemName: "exclamationmark.triangle").foregroundColor(.red) :
        Image(systemName: "checkmark.circle").foregroundColor(.green)
        
        let toast = ToastValue(icon: icon, message: message)
        presentToast(toast)
        
        if isError {
            viewModel.errorMessage = nil
            playHapticFeedback(.error)
        } else {
            viewModel.successMessage = nil
            playHapticFeedback(.success)
        }
    }
    
    private func playHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    private func playImpactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
