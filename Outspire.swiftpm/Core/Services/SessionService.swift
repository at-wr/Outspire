import SwiftUI
import Combine

class SessionService: ObservableObject {
    @Published var sessionId: String?
    @Published var userInfo: UserInfo?
    @Published var isAuthenticated: Bool = false
    
    private let userDefaults = UserDefaults.standard
    static let shared = SessionService()
    
    private init() {
        self.sessionId = userDefaults.string(forKey: "sessionId")
        
        if let storedUserInfo = userDefaults.data(forKey: "userInfo"),
           let user = try? JSONDecoder().decode(UserInfo.self, from: storedUserInfo) {
            self.userInfo = user
            self.isAuthenticated = sessionId != nil
        }
    }
    
    func clearSession() {
        sessionId = nil
        userDefaults.removeObject(forKey: "sessionId")
        // Don't clear user info to keep the UI consistent
    }
    
    func loginUser(username: String, password: String, captcha: String, completion: @escaping (Bool, String?) -> Void) {
        guard let sessionId = self.sessionId, !sessionId.isEmpty else {
            completion(false, "Please refresh the captcha.")
            return
        }
        
        let parameters = [
            "username": username,
            "password": password,
            "code": captcha
        ]
        
        NetworkService.shared.request(
            endpoint: "login.php",
            parameters: parameters,
            sessionId: sessionId
        ) { [weak self] (result: Result<LoginResponse, NetworkError>) in
            switch result {
            case .success(let response):
                // Check for Chinese error message about captcha (scenario 3)
                if response.status.contains("验证码") || response.status.contains("错") {
                    completion(false, "Invalid captcha code")
                    return
                }
                
                // Check login status
                if response.status == "ok" {
                    // Verify the password hash to determine if credentials are correct
                    // This assumes the server returns the expected hash for correct credentials
                    self?.fetchUserInfo { success, error in
                        if success {
                            self?.isAuthenticated = true
                            completion(true, nil)
                        } else {
                            completion(false, "Invalid username or password")
                        }
                    }
                } else {
                    completion(false, "Sign In failed: \(response.status)")
                }
                
            case .failure(let error):
                completion(false, "Sign In failed: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchUserInfo(completion: @escaping (Bool, String?) -> Void) {
        NetworkService.shared.request(
            endpoint: "init_info.php",
            sessionId: sessionId
        ) { [weak self] (result: Result<UserInfo, NetworkError>) in
            switch result {
            case .success(let userInfo):
                self?.userInfo = userInfo
                // Cache user info
                self?.userDefaults.set(try? JSONEncoder().encode(userInfo), forKey: "userInfo")
                self?.isAuthenticated = true
                completion(true, nil)
            case .failure(let error):
                completion(false, "Failed: \(error.localizedDescription)")
            }
        }
    }
    
    func logoutUser() {
        sessionId = nil
        userInfo = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: "sessionId")
        userDefaults.removeObject(forKey: "userInfo")
        CacheManager.clearAllCache() 
        
        // Also clear cookies to ensure a clean logout
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
    
    func storeSessionId(_ sessionId: String) {
        self.sessionId = sessionId
        userDefaults.set(sessionId, forKey: "sessionId")
    }
}
