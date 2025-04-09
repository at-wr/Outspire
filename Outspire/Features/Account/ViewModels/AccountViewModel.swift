import SwiftUI
import Combine
import Toasts
import Vision

class AccountViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var captcha: String = ""
    @Published var captchaImageData: Data?
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isCaptchaLoading: Bool = false
    @Published var isLoggingIn: Bool = false
    @Published var isRecognizingCaptcha: Bool = false
    @Published var isAutoRetrying: Bool = false
    @Published var autoRetryCount: Int = 0
    private let maxVisibleRetryCount = 10

    private let sessionService = SessionService.shared
    private let userDefaults = UserDefaults.standard

    var isAuthenticated: Bool {
        sessionService.isAuthenticated
    }

    var userInfo: UserInfo? {
        sessionService.userInfo
    }

    init() {
        // Listen for authentication status changes
        NotificationCenter.default.addObserver(
            forName: Notification.Name.authenticationStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func fetchCaptchaImage() {
        guard !isLoggingIn else { return }

        isCaptchaLoading = true

        self.captcha = ""
        self.captchaImageData = nil

        sessionService.clearSession()

        guard let captchaURL = URL(string: "\(Configuration.baseURL)/php/login_key.php") else {
            self.errorMessage = "Invalid CAPTCHA URL"
            self.isCaptchaLoading = false
            return
        }

        print("Fetching fresh captcha from: \(captchaURL)")

        let cookieStorage = HTTPCookieStorage.shared
        if let cookies = cookieStorage.cookies {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }

        var request = URLRequest(url: captchaURL)
        request.httpShouldHandleCookies = true
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCaptchaLoading = false

                if let error = error {
                    print("Captcha fetch error: \(error.localizedDescription)")
                    self.errorMessage = "\(error.localizedDescription)"
                    return
                }

                if let data = data {
                    self.captchaImageData = data

                    if let sessionId = self.extractSessionId(from: response) {
                        print("Extracted session ID: \(sessionId)")
                        self.sessionService.updateSessionId(sessionId)

                        self.isRecognizingCaptcha = true
                        CaptchaRecognizer.recognizeText(in: data, method: .combined) { recognizedText in
                            DispatchQueue.main.async {
                                self.isRecognizingCaptcha = false
                                if let text = recognizedText {
                                    print("Recognized captcha: \(text)")
                                    self.captcha = text
                                }
                            }
                        }
                    } else {
                        print("Failed to extract session ID from response")
                        self.errorMessage = "Retrying..."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchCaptchaImage()
                        }
                    }
                } else {
                    self.errorMessage = "Retrying..."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.fetchCaptchaImage()
                    }
                }
            }
        }.resume()
    }

    func login(autoRetry: Bool = false) {
        guard !username.isEmpty, !password.isEmpty, !captcha.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }

        guard let sessionId = sessionService.sessionId, !sessionId.isEmpty else {
            errorMessage = "Retrying..."
            fetchCaptchaImage()
            return
        }

        isLoggingIn = true

        if autoRetry {
            autoRetryCount += 1
            isAutoRetrying = true
        } else {
            errorMessage = nil
            successMessage = nil
        }

        print("Attempting login with username: \(username), captcha: \(captcha), autoRetry: \(autoRetry)")

        sessionService.loginUser(username: username, password: password, captcha: captcha) { [weak self] success, error, isCaptchaError in
            guard let self = self else { return }

            if success {
                self.isLoggingIn = false
                self.isAutoRetrying = false
                self.autoRetryCount = 0

                print("Login successful")
                self.username = ""
                self.password = ""
                self.captcha = ""
                self.captchaImageData = nil
                self.successMessage = "Signed in successfully"
                NotificationCenter.default.post(
                    name: Notification.Name.authenticationStatusChanged,
                    object: nil,
                    userInfo: ["action": "signedin"]
                )
                DispatchQueue.main.async {
                    self.successMessage = "Signed in successfully"
                }
            } else if isCaptchaError {
                print("CAPTCHA error, retrying... Attempt #\(self.autoRetryCount)")

                self.fetchCaptchaAndRetry()
            } else {
                self.isLoggingIn = false
                self.isAutoRetrying = false
                self.autoRetryCount = 0

                print("Login failed with non-captcha error: \(error ?? "Unknown error")")
                DispatchQueue.main.async {
                    let userFriendlyError: String
                    if let errorMsg = error?.lowercased() {
                        if errorMsg == "no" {
                            userFriendlyError = "Invalid username or password"
                        } else if errorMsg.contains("captcha") {
                            userFriendlyError = "Incorrect CAPTCHA. Please try again"
                        } else {
                            userFriendlyError = "Login failed: \(error!)"
                        }
                    } else {
                        userFriendlyError = "Login failed. Please try again"
                    }
                    self.errorMessage = userFriendlyError
                }
                // Refresh captcha on failure
                self.fetchCaptchaImage()
            }
        }
    }

    private func fetchCaptchaAndRetry() {
        self.captcha = ""
        self.captchaImageData = nil

        sessionService.clearSession()

        guard let captchaURL = URL(string: "\(Configuration.baseURL)/php/login_key.php") else {
            self.errorMessage = "Invalid CAPTCHA URL."
            self.isLoggingIn = false
            self.isAutoRetrying = false
            return
        }

        let cookieStorage = HTTPCookieStorage.shared
        if let cookies = cookieStorage.cookies {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }

        var request = URLRequest(url: captchaURL)
        request.httpShouldHandleCookies = true
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    print("Captcha fetch error during auto-retry: \(error.localizedDescription)")
                    // Even if there's an error, keep trying
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.fetchCaptchaAndRetry() // Recursive retry
                    }
                    return
                }

                if let data = data {
                    self.captchaImageData = data

                    if let sessionId = self.extractSessionId(from: response) {
                        self.sessionService.updateSessionId(sessionId)

                        // Try to recognize the captcha
                        CaptchaRecognizer.recognizeText(in: data, method: .combined) { recognizedText in
                            DispatchQueue.main.async {
                                if let text = recognizedText, !text.isEmpty {
                                    self.captcha = text

                                    // Wait a moment then retry login
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        self.login(autoRetry: true) // Retry with recognized captcha
                                    }
                                } else {
                                    // Failed to recognize - try again
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        self.fetchCaptchaAndRetry() // Recursive retry
                                    }
                                }
                            }
                        }
                    } else {
                        print("Failed to extract session ID - retrying")
                        // Failed to get session ID - try again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchCaptchaAndRetry() // Recursive retry
                        }
                    }
                } else {
                    // No data - try again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.fetchCaptchaAndRetry() // Recursive retry
                    }
                }
            }
        }.resume()
    }

    func logout() {
        // Call the session service logout
        sessionService.logoutUser()

        // Reset all local state
        username = ""
        password = ""
        captcha = ""

        // Fetch a new captcha
        fetchCaptchaImage()

        // Show success message
        successMessage = "Signed out from TSIMS"

        // Notify that authentication status has changed with additional context
        NotificationCenter.default.post(
            name: Notification.Name.authenticationStatusChanged,
            object: nil,
            userInfo: ["action": "logout"]
        )
        DispatchQueue.main.async {
            self.successMessage = "Signed out successfully"
        }
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
