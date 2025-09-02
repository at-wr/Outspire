import SwiftUI

struct ProfileHeaderView: View {
    @ObservedObject private var authV2 = AuthServiceV2.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isAuthenticated ? "person.crop.circle" : "person.fill.viewfinder")
                .font(.system(size: 28))
                .foregroundStyle(isAuthenticated ? .cyan : .gray)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.headline)
                if isAuthenticated {
                    if let code = authV2.user?.userCode {
                        Text("Code: \(code)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("with your TSIMS account")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var displayName: String {
        if isAuthenticated { return authV2.user?.name ?? "Account" }
        else { return "Sign In" }
    }

    private var isAuthenticated: Bool {
        return authV2.isAuthenticated
    }
}
