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
    @State private var lastToastId = UUID()
    @State private var captchaImage: Image?

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
        .onChange(of: viewModel.captchaImageData) { _, imageData in
            if let data = imageData, let uiImage = UIImage(data: data) {
                captchaImage = Image(uiImage: uiImage)
            } else {
                captchaImage = nil
            }
        }
        .id(viewModel.isAuthenticated)
    }

    private var loginView: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 64))
                            .foregroundStyle(.primary)
                            .symbolRenderingMode(.hierarchical)
                            .padding(.vertical)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    TextField("Username of TSIMS", text: $viewModel.username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                            login()
                        }

                    HStack {
                        TextField("CAPTCHA", text: $viewModel.captcha)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .captcha)
                            .submitLabel(.done)
                            .foregroundStyle(.secondary)
                            .onSubmit {
                                focusedField = nil
                                login()
                            }

                        if focusedField == .captcha {
                            captchaImageView
                                .frame(width: 67.5, height: 30)
                        }
                    }

                }

                Section {
                    VStack(spacing: 2) {
                        Image(systemName: "lock.circle.dotted")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 24))
                        let baseText = "For account issues, contact school faculty. All data will only be stored on this device and the TSIMS server. "
                        let connectionStatus = Configuration.useSSL ?
                        "Your connection with Relay Server is end-to-end encrypted." :
                        "Your connection can be easily discovered by other users. Relay Encryption is strongly recommended if you're using a public network."

                        Text(baseText + connectionStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.top, 2)
                }

                Section {
                    Button(action: login) {
                        HStack {
                            Spacer()
                            ZStack {
                                if viewModel.isLoggingIn || viewModel.isAutoRetrying {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Continue")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            Spacer()
                        }
                        .frame(height: 46)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoggingIn)
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                }

            }
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: viewModel.isAuthenticated) { _, newValue in
                if newValue {
                    withAnimation { isTransitioning = true }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation { isTransitioning = false }
                        NotificationCenter.default.post(name: Notification.Name.authenticationStatusChanged, object: nil)
                    }
                }
            }
        }
    }

    private var loggedInView: some View {
        Form {
            Section("Account Information") {
                if let userInfo = viewModel.userInfo {
                    LabeledContent("Name", value: "\(userInfo.studentname) (\(userInfo.nickname))")
                    LabeledContent("Student ID", value: userInfo.studentid)
                    LabeledContent("Student No", value: userInfo.studentNo)
                }
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    showLogoutConfirmation = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                viewModel.logout()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var captchaImageView: some View {
        ZStack {
            // Background placeholder that maintains consistent size
            Rectangle()
                .fill(Color.clear)
                .frame(width: 67.5, height: 30)

            Group {
                if viewModel.isCaptchaLoading {
                    ProgressView()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                } else if let image = captchaImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(8)
                        .onTapGesture { refreshCaptcha() }
                } else {
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .onTapGesture { viewModel.fetchCaptchaImage() }
                }
            }
            .frame(width: 67.5, height: 30)
        }
        // Disable animations for changing states
        .animation(.none, value: viewModel.isCaptchaLoading)
        .animation(.none, value: captchaImage)
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

        // Create icon for the toast
        let icon = isError ?
        Image(systemName: "exclamationmark.triangle").foregroundColor(.red) :
        Image(systemName: "checkmark.circle").foregroundColor(.green)

        // Create toast value
        let toast = ToastValue(icon: icon, message: message)

        // Present toast with small delay to ensure it appears after UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.presentToast(toast)

            // Play feedback after toast appears
            if isError {
                self.playHapticFeedback(.error)
            } else {
                self.playHapticFeedback(.success)
            }
        }

        // Clear messages
        if isError {
            viewModel.errorMessage = nil
        } else {
            viewModel.successMessage = nil
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
