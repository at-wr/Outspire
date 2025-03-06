import SwiftUI
import Combine

class AccountViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var captcha: String = ""
    @Published var captchaImageData: Data?
    @Published var errorMessage: String?
    @Published var isCaptchaLoading: Bool = false
    
    private let sessionService = SessionService.shared
    private let userDefaults = UserDefaults.standard
    
    var isAuthenticated: Bool {
        sessionService.isAuthenticated
    }
    
    var userInfo: UserInfo? {
        sessionService.userInfo
    }
    
    init() {
        if let storedCaptcha = userDefaults.data(forKey: "captchaImageData") {
            self.captchaImageData = storedCaptcha
        }
    }
    
    func fetchCaptchaImage() {
        isCaptchaLoading = true
        errorMessage = nil
        
        guard let captchaURL = URL(string: "\(Configuration.baseURL)/php/login_key.php") else {
            self.errorMessage = "Invalid CAPTCHA URL."
            self.isCaptchaLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: captchaURL) { [weak self] data, response, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCaptchaLoading = false
                
                if let data = data {
                    self.captchaImageData = data
                    self.userDefaults.set(data, forKey: "captchaImageData")
                    
                    // Extract session ID from response
                    if let sessionId = self.extractSessionId(from: response) {
                        self.sessionService.storeSessionId(sessionId)
                    }
                } else {
                    self.errorMessage = "Failed to load CAPTCHA."
                }
            }
        }.resume()
    }
    
    func login() {
        guard !username.isEmpty, !password.isEmpty, !captcha.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isCaptchaLoading = true
        errorMessage = nil
        
        sessionService.loginUser(username: username, password: password, captcha: captcha) { [weak self] success, error in
            self?.isCaptchaLoading = false
            
            if !success {
                self?.errorMessage = error
                self?.fetchCaptchaImage() // Refresh captcha on failure
            }
        }
    }
    
    func logout() {
        sessionService.logoutUser()
        fetchCaptchaImage()
    }
    
    private func extractSessionId(from response: URLResponse?) -> String? {
        guard let httpResponse = response as? HTTPURLResponse,
              let setCookie = httpResponse.allHeaderFields["Set-Cookie"] as? String else {
            return nil
        }
        
        let pattern = "PHPSESSID=([^;]+)"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: setCookie, options: [], range: NSRange(location: 0, length: setCookie.utf16.count)),
           let range = Range(match.range(at: 1), in: setCookie) {
            return String(setCookie[range])
        }
        return nil
    }
}