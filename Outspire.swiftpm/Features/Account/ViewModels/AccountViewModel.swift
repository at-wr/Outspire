import SwiftUI
import Combine

class AccountViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var captcha: String = ""
    @Published var captchaImageData: Data?
    @Published var errorMessage: String?
    @Published var isCaptchaLoading: Bool = false
    @Published var isLoggingIn: Bool = false
    
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
        // Don't refresh captcha if we're in the middle of logging in
        guard !isLoggingIn else { return }
        
        isCaptchaLoading = true
        errorMessage = nil
        
        guard let captchaURL = URL(string: "\(Configuration.baseURL)/php/login_key.php") else {
            self.errorMessage = "Invalid CAPTCHA URL."
            self.isCaptchaLoading = false
            return
        }
        
        print("Fetching captcha from: \(captchaURL)")
        
        URLSession.shared.dataTask(with: captchaURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCaptchaLoading = false
                
                if let error = error {
                    print("Captcha fetch error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load CAPTCHA: \(error.localizedDescription)"
                    return
                }
                
                if let data = data {
                    self.captchaImageData = data
                    self.userDefaults.set(data, forKey: "captchaImageData")
                    
                    // Extract session ID from response
                    if let sessionId = self.extractSessionId(from: response) {
                        print("Extracted session ID: \(sessionId)")
                        self.sessionService.storeSessionId(sessionId)
                    } else {
                        print("Failed to extract session ID from response")
                        self.errorMessage = "Failed to get session. Try refreshing captcha."
                    }
                } else {
                    self.errorMessage = "Failed to load CAPTCHA: No data received"
                }
            }
        }.resume()
    }
    
    func login() {
        guard !username.isEmpty, !password.isEmpty, !captcha.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        // Ensure we have a session ID before attempting login
        guard sessionService.sessionId != nil else {
            errorMessage = "Missing session ID. Please refresh the captcha and try again."
            fetchCaptchaImage()
            return
        }
        
        // Set state to logging in to prevent multiple attempts
        isLoggingIn = true
        isCaptchaLoading = true
        errorMessage = nil
        
        print("Attempting login with username: \(username), captcha: \(captcha)")
        
        sessionService.loginUser(username: username, password: password, captcha: captcha) { [weak self] success, error in
            guard let self = self else { return }
            
            self.isLoggingIn = false
            self.isCaptchaLoading = false
            
            if success {
                print("Login successful")
                // Clear form fields on successful login
                self.username = ""
                self.password = ""
                self.captcha = ""
            } else {
                print("Login failed: \(error ?? "Unknown error")")
                self.errorMessage = error
                // Only refresh captcha on failure
                self.fetchCaptchaImage() 
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
