import Combine
import SwiftUI

@MainActor
class SessionService: ObservableObject {
    @Published var sessionId: String?
    @Published var userInfo: UserInfo?
    @Published var isAuthenticated: Bool = false {
        didSet {
            // Notify about authentication changes
            NotificationCenter.default.post(name: .authStateDidChange, object: nil)
        }
    }

    private let userDefaults = UserDefaults.standard
    static let shared = SessionService()

    private init() {
        // Migrate sessionId from UserDefaults to Keychain (backward compatible)
        let defaultsSession = userDefaults.string(forKey: "sessionId")
        let keychainSession = SecureStore.get("sessionId")

        if let keychainSession, !keychainSession.isEmpty {
            self.sessionId = keychainSession
        } else if let defaultsSession, !defaultsSession.isEmpty {
            // One-time migration: move to Keychain and keep defaults for older builds if needed
            self.sessionId = defaultsSession
            SecureStore.set(defaultsSession, for: "sessionId")
        } else {
            self.sessionId = nil
        }

        if let storedUserInfo = userDefaults.data(forKey: "userInfo"),
            let user = try? JSONDecoder().decode(UserInfo.self, from: storedUserInfo)
        {
            self.userInfo = user
            self.isAuthenticated = sessionId != nil
        }
    }

    func clearSession() {
        sessionId = nil
        // Remove from both stores
        userDefaults.removeObject(forKey: "sessionId")
        SecureStore.remove("sessionId")
        // Don't clear user info to keep the UI consistent
    }

    // Update the loginUser method
    func loginUser(
        username: String, password: String, captcha: String,
        completion: @escaping (Bool, String?, Bool) -> Void
    ) {
        guard let sessionId = self.sessionId, !sessionId.isEmpty else {
            completion(false, "Please refresh the captcha.", true)  // Mark as captcha error to trigger retry
            return
        }

        let parameters = [
            "username": username,
            "password": password,
            "code": captcha,
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
                    completion(false, "Invalid captcha code. Retrying...", true)  // Mark as captcha error
                    return
                }

                // Check login status
                if response.status == "ok" {
                    self?.fetchUserInfo { success, _ in
                        if success {
                            self?.isAuthenticated = true
                            completion(true, nil, false)
                        } else {
                            completion(false, "Invalid username or password.", false)
                        }
                    }
                } else {
                    completion(false, "Login failed: \(response.status)", false)
                }

            case .failure(let error):
                completion(false, "Login failed: \(error.localizedDescription)", false)
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
        // Need to call objectWillChange before changing published properties
        objectWillChange.send()

        // Clear all authentication state
        sessionId = nil
        userInfo = nil
        isAuthenticated = false

        // Clear schedule settings
        Configuration.selectedDayOverride = nil
        Configuration.setAsToday = false
        Configuration.isHolidayMode = false
        Configuration.holidayHasEndDate = false
        Configuration.holidayEndDate = Date()

        // Clear cookies
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }

        // Reset the network session
        URLSession.shared.reset {}

        // Clear user defaults
        userDefaults.removeObject(forKey: "sessionId")
        userDefaults.removeObject(forKey: "userInfo")
        userDefaults.removeObject(forKey: "selectedDayOverride")
        userDefaults.removeObject(forKey: "setAsToday")
        userDefaults.removeObject(forKey: "isHolidayMode")
        userDefaults.removeObject(forKey: "holidayHasEndDate")

        // Cancel all notifications when user logs out
        NotificationManager.shared.cancelAllNotifications()

        // Clear all cached data to prevent leakage across accounts
        CacheManager.clearAllCache()

        // Clear URLCache to remove any cached responses
        URLCache.shared.removeAllCachedResponses()

        // Post notification that authentication has changed
        NotificationCenter.default.post(
            name: .authenticationStatusChanged,
            object: nil,
            userInfo: ["action": "logout"]
        )
    }

    // Public method to update session ID
    func updateSessionId(_ sessionId: String) {
        storeSessionId(sessionId)
    }

    private func storeSessionId(_ sessionId: String) {
        self.sessionId = sessionId
        // Write to Keychain primarily; mirror to defaults for compatibility with very old builds
        SecureStore.set(sessionId, for: "sessionId")
        userDefaults.set(sessionId, forKey: "sessionId")
    }
}
