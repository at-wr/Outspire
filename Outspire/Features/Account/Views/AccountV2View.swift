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
        Form {
            Section {
                TextField("Code (e.g. s20230001)", text: $viewModel.code)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .code)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil; login() }
            }

            Section {
                Button(action: login) {
                    HStack { Spacer()
                        if viewModel.isLoggingIn { ProgressView().tint(.white) }
                        else { Text("Continue").font(.headline).foregroundColor(.white) }
                        Spacer() }
                    .frame(height: 46)
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoggingIn)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Account")
        .toolbarBackground(Color(UIColor.secondarySystemBackground))
    }

    private var loggedInView: some View {
        Form {
            Section("Account Information") {
                if let user = viewModel.user {
                    LabeledContent("Name", value: user.name ?? "")
                    if let code = user.userCode { LabeledContent("Code", value: code) }
                    if let role = user.role { LabeledContent("Role", value: role) }
                }
            }
            Section {
                Button("Sign Out", role: .destructive) { showLogoutConfirmation = true }
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Account")
        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) { viewModel.logout() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func login() { viewModel.login() }

    private func showToast(_ message: String?, isError: Bool) {
        guard let message = message else { return }
        let icon = isError ? Image(systemName: "exclamationmark.triangle").foregroundColor(.red) : Image(systemName: "checkmark.circle").foregroundColor(.green)
        let toast = ToastValue(icon: icon, message: message)
        presentToast(toast)
        if isError { viewModel.errorMessage = nil } else { viewModel.successMessage = nil }
    }
}

