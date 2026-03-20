import SwiftUI

struct ProfileHeaderView: View {
    @ObservedObject private var authV2 = AuthServiceV2.shared

    var body: some View {
        HStack(spacing: 14) {
            // iOS-style avatar with subtle glow
            Image(systemName: isAuthenticated ? "person.crop.circle.fill" : "person.crop.circle")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isAuthenticated ? AppColor.brand : .gray.opacity(0.6))
                .shadow(color: isAuthenticated ? AppColor.brand.opacity(0.2) : .clear, radius: 6, y: 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(AppText.sectionTitle)
                if isAuthenticated {
                    if let code = authV2.user?.userCode {
                        Text(code)
                            .font(AppText.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Sign in with TSIMS")
                        .font(AppText.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, AppSpace.xxs + 2)
    }

    private var displayName: String {
        if isAuthenticated { return authV2.user?.name ?? "Account" }
        return "Sign In"
    }

    private var isAuthenticated: Bool {
        authV2.isAuthenticated
    }
}
