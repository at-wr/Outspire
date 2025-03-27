import SwiftUI

struct ProfileHeaderView: View {
    @EnvironmentObject var sessionService: SessionService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sessionService.isAuthenticated ? "person.crop.circle" : "person.fill.viewfinder")
                .font(.system(size: 28))
                .foregroundStyle(sessionService.isAuthenticated ? .cyan : .gray)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.headline)
                if sessionService.isAuthenticated, let studentNo = sessionService.userInfo?.studentNo {
                    Text("Student No: \(studentNo)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !sessionService.isAuthenticated {
                    Text("with your TSIMS account")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var displayName: String {
        if sessionService.isAuthenticated {
            let studentName = sessionService.userInfo?.studentname ?? ""
            let nickname = sessionService.userInfo?.nickname ?? ""
            return (studentName.isEmpty && nickname.isEmpty) ? "Account" : "\(studentName) \(nickname)".trimmingCharacters(in: .whitespaces)
        }
        return "Sign In"
    }
}
