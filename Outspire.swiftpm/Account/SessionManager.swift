import SwiftUI
import Combine

class SessionManager: ObservableObject {
    @Published var sessionId: String?
    @Published var userInfo: UserInfo?   // Add userInfo property
    
    static let shared = SessionManager()  // Singleton instance
    
    private init() {
        self.sessionId = UserDefaults.standard.string(forKey: "sessionId")
        
        if let storedUserInfo = UserDefaults.standard.data(forKey: "userInfo"),
           let user = try? JSONDecoder().decode(UserInfo.self, from: storedUserInfo) {
            self.userInfo = user
        }
    }
}
