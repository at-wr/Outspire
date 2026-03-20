import SwiftUI
import Toasts

struct AccountV2View: View {
    @Environment(\.presentToast) var presentToast
    @StateObject var viewModel = AccountV2ViewModel()
    @State private var showLogoutConfirmation = false
    @FocusState private var focusedField: Field?

    enum Field { case code, password }

    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                loggedInView
            } else {
                loginView
            }
        }
        .onChange(of: viewModel.errorMessage) { _, msg in showToast(msg, isError: true) }
        .onChange(of: viewModel.successMessage) { _, msg in showToast(msg, isError: false) }
    }

    private var loginView: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                // Hero icon
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(AppColor.brand.gradient)
                    .shadow(color: AppColor.brand.opacity(0.3), radius: 12, y: 6)

                VStack(spacing: 6) {
                    Text("Welcome")
                        .font(.title.weight(.bold))
                    Text("Sign in with your TSIMS account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Input fields
                VStack(spacing: 14) {
                    TextField("Student Code", text: $viewModel.code)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .code)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                        .padding(14)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil; login() }
                        .padding(14)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
                .padding(.horizontal, 4)

                // Sign in button
                Button(action: login) {
                    HStack {
                        Spacer()
                        if viewModel.isLoggingIn {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 15)
                    .coloredRichCard(
                        colors: [AppColor.brand.opacity(0.9), AppColor.brand.opacity(0.7)],
                        cornerRadius: AppRadius.md,
                        shadowRadius: 8
                    )
                }
                .disabled(viewModel.isLoggingIn)
                .buttonStyle(.pressableCard)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Account")
    }

    private var loggedInView: some View {
        List {
            // Profile hero section
            Section {
                if let user = viewModel.user {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            // iOS-style avatar
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 52))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.gray)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(user.name ?? "User")
                                    .font(.title3.weight(.bold))
                                if let code = user.userCode {
                                    Text(code)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                if let role = user.role {
                                    Text(role)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            Section {
                Button(role: .destructive) {
                    HapticManager.shared.playButtonTap()
                    showLogoutConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Account")
        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                HapticManager.shared.playWarningFeedback()
                viewModel.logout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func login() {
        HapticManager.shared.playButtonTap()
        viewModel.login()
    }

    private func showToast(_ message: String?, isError: Bool) {
        guard let message else { return }
        let icon = isError
            ? Image(systemName: "exclamationmark.triangle").foregroundColor(.red)
            : Image(systemName: "checkmark.circle").foregroundColor(.green)
        let toast = ToastValue(icon: icon, message: message)
        presentToast(toast)
        if isError { viewModel.errorMessage = nil } else { viewModel.successMessage = nil }
    }
}
