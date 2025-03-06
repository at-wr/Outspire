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
    
    func loginUser(username: String, password: String, captcha: String, completion: @escaping (Bool, String?) -> Void) {
        guard let sessionId = self.sessionId else {
            completion(false, "Session ID is missing.")
            return
        }
        
        let parameters = [
            "username": username,
            "password": password,
            "code": captcha
        ]
        
        NetworkService.shared.request<LoginResponse>(
            endpoint: "login.php",
            parameters: parameters,
            sessionId: sessionId
        ) { [weak self] result in
            switch result {
            case .success(let response):
                if response.status == "ok" {
                    self?.fetchUserInfo { success, error in
                        if success {
                            self?.isAuthenticated = true
                        }
                        completion(success, error)
                    }
                } else {
                    completion(false, "Invalid login credentials.")
                }
            case .failure(let error):
                completion(false, "Login failed: \(error)")
            }
        }
    }
    
    func fetchUserInfo(completion: @escaping (Bool, String?) -> Void) {
        NetworkService.shared.request<UserInfo>(
            endpoint: "init_info.php",
            sessionId: sessionId
        ) { [weak self] result in
            switch result {
            case .success(let userInfo):
                self?.userInfo = userInfo
                // Cache user info
                self?.userDefaults.set(try? JSONEncoder().encode(userInfo), forKey: "userInfo")
                self?.isAuthenticated = true
                completion(true, nil)
            case .failure(let error):
                completion(false, "Failed to fetch user info: \(error)")
            }
        }
    }
    
    func logoutUser() {
        sessionId = nil
        userInfo = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: "sessionId")
        userDefaults.removeObject(forKey: "userInfo")
    }
    
    func storeSessionId(_ sessionId: String) {
        self.sessionId = sessionId
        userDefaults.set(sessionId, forKey: "sessionId")
    }
}