import SwiftUI

struct TodayView: View {
    @EnvironmentObject var sessionService: SessionService
    
    var greeting: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            return "Morning"
        case 12..<18:
            return "Good Afternoon"
        default:
            return "Evening"
        }
    }
    
    var body: some View {
        VStack {
            if let nickname = sessionService.userInfo?.nickname {
                VStack {
                    Text("\(greeting), \(nickname)")
                        .font(.title2)
                }
                .navigationTitle("\(greeting)")
            } else {
                VStack {
                    Text("Welcome to Outspire")
                        .foregroundStyle(.primary)
                        .font(.title2)
                    Text("Sign in with WFLA TSIMS account to continue")
                        .foregroundStyle(.secondary)
                    Text("(Settings Icon > Account > Sign In)")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .onAppear {
            // Get user info if authenticated but no user info is loaded
            if sessionService.isAuthenticated && sessionService.userInfo == nil {
                sessionService.fetchUserInfo { _, _ in }
            }
        }
    }
}