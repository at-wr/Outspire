import SwiftUI
import Combine
import Toasts

class AccountViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var captcha: String = ""
    @Published var captchaImageData: Data?
    @Published var errorMessage: String?
    @Published var successMessage: String?
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
        // No longer loading cached captcha on init
        // Always fetch a fresh captcha when view appears
    }
    
    func fetchCaptchaImage() {
        // Only prevent refresh during active login process
        guard !isLoggingIn else { return }
        
        isCaptchaLoading = true
        
        // Don't clear error messages here - let the view handle that
        // This ensures the toast has time to display
        
        // Clear previous captcha
        self.captcha = ""
        self.captchaImageData = nil
        
        // Clear previous session to ensure a fresh one
        sessionService.clearSession()
        
        guard let captchaURL = URL(string: "\(Configuration.baseURL)/php/login_key.php") else {
            self.errorMessage = "Invalid CAPTCHA URL."
            self.isCaptchaLoading = false
            return
        }
        
        print("Fetching fresh captcha from: \(captchaURL)")
        
        // Clear any cookies to ensure a fresh session
        let cookieStorage = HTTPCookieStorage.shared
        if let cookies = cookieStorage.cookies {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }
        
        var request = URLRequest(url: captchaURL)
        request.httpShouldHandleCookies = true
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
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
                    
                    // Extract session ID from response
                    if let sessionId = self.extractSessionId(from: response) {
                        print("Extracted session ID: \(sessionId)")
                        self.sessionService.storeSessionId(sessionId)
                    } else {
                        print("Failed to extract session ID from response")
                        self.errorMessage = "Failed to get session. Retrying automatically..."
                        // Automatic retry after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchCaptchaImage()
                        }
                    }
                } else {
                    self.errorMessage = "Failed to load CAPTCHA: No data received. Retrying..."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.fetchCaptchaImage()
                    }
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
        guard let sessionId = sessionService.sessionId, !sessionId.isEmpty else {
            errorMessage = "Missing session ID. Refreshing captcha..."
            fetchCaptchaImage()
            return
        }
        
        // Set state to logging in to prevent multiple attempts
        isLoggingIn = true
        
        print("Attempting login with username: \(username), captcha: \(captcha)")
        
        sessionService.loginUser(username: username, password: password, captcha: captcha) { [weak self] success, error in
            guard let self = self else { return }
            
            self.isLoggingIn = false
            
            if success {
                print("Login successful")
                // Clear form fields on successful login
                self.username = ""
                self.password = ""
                self.captcha = ""
                self.successMessage = "Signed in to TSIMS"
            } else {
                print("Login failed: \(error ?? "Unknown error")")
                self.errorMessage = error ?? "Login failed. Please try again."
                // Always refresh captcha on failure
                self.fetchCaptchaImage()
            }
        }
    }
    
    func logout() {
        sessionService.logoutUser()
        fetchCaptchaImage()
        successMessage = "Signed out from TSIMS"
    }
    
    private func extractSessionId(from response: URLResponse?) -> String? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        
        // Try to get session ID from cookies first
        if let cookies = HTTPCookieStorage.shared.cookies(for: httpResponse.url!) {
            for cookie in cookies {
                if cookie.name == "PHPSESSID" {
                    return cookie.value
                }
            }
        }
        
        // Fall back to header extraction if cookie access fails
        if let setCookie = httpResponse.allHeaderFields["Set-Cookie"] as? String {
            let pattern = "PHPSESSID=([^;]+)"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: setCookie, options: [], range: NSRange(location: 0, length: setCookie.utf16.count)),
               let range = Range(match.range(at: 1), in: setCookie) {
                return String(setCookie[range])
            }
        }
        return nil
    }
}
