import SwiftUI
import Combine

class SessionManager: ObservableObject {
    @Published var sessionId: String?
    @Published var userInfo: UserInfo?
    
    static let shared = SessionManager() // Singleton instance
    
    private init() {
        self.sessionId = UserDefaults.standard.string(forKey: "sessionId")
        
        if let storedUserInfo = UserDefaults.standard.data(forKey: "userInfo"),
           let user = try? JSONDecoder().decode(UserInfo.self, from: storedUserInfo) {
            self.userInfo = user
        }
    }
    
    func refreshUserInfo(completion: (() -> Void)? = nil) {
        guard let sessionId = self.sessionId,
              let infoURL = URL(string: "\(Configuration.baseURL)/php/init_info.php") else {
            completion?()
            return
        }
        
        var request = URLRequest(url: infoURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers(for: sessionId)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else {
                    completion?()
                    return
                }
                do {
                    self.userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
                    // Cache userInfo
                    UserDefaults.standard.set(try? JSONEncoder().encode(self.userInfo), forKey: "userInfo")
                } catch {
                    print("Failed to parse user info: \(error.localizedDescription)")
                }
                completion?()
            }
        }.resume()
    }
    
    private func headers(for sessionId: String?) -> [String: String]? {
        guard let sessionId = sessionId else { return nil }
        return [
            "Content-Type": "application/x-www-form-urlencoded",
            "Cookie": "PHPSESSID=\(sessionId)"
        ]
    }
}
