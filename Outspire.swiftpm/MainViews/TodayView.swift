import SwiftUI

struct TodayView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    
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
            if let nickname = sessionManager.userInfo?.nickname {
                VStack {
                    Text("\(greeting), \(nickname)")
                        .font(.title2)
                }
                // .navigationTitle("Today")
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
            sessionManager.refreshUserInfo()
        }
            
        // .navigationTitle("\(greeting), \(sessionManager.userInfo?.nickname ?? "Welcome")")
    }
}

struct HelloWorldView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
    }
}
