import SwiftUI

struct AccountDetailsView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var captcha: String = ""
    @State private var showLogoutConfirmation = false
    @State private var captchaImageData: Data? {
        didSet {
            if let data = captchaImageData {
                UserDefaults.standard.set(data, forKey: "captchaImageData")
            } else {
                UserDefaults.standard.removeObject(forKey: "captchaImageData")
            }
        }
    }
    @State private var errorMessage: String?
    @State private var isCaptchaLoading: Bool = false
    @State private var userInfo: UserInfo? {
        didSet {
            if let userInfo = userInfo {
                UserDefaults.standard.set(try? JSONEncoder().encode(userInfo), forKey: "userInfo")
            } else {
                UserDefaults.standard.removeObject(forKey: "userInfo")
            }
        }
    }
    @State private var sessionId: String? {
        didSet {
            UserDefaults.standard.set(sessionId, forKey: "sessionId")
        }
    }
    
    let connectionStatus = Configuration.useSSL ? "\nYour connection has been encrypted." : "\nYour connection hasn't been encrypted.\nRelay Encryption was suggested if you're using a public network."
    
    init() {
        self._sessionId = State(initialValue: UserDefaults.standard.string(forKey: "sessionId"))
        if let storedUserInfo = UserDefaults.standard.data(forKey: "userInfo"),
           let user = try? JSONDecoder().decode(UserInfo.self, from: storedUserInfo) {
            self._userInfo = State(initialValue: user)
        }
        if let storedCaptcha = UserDefaults.standard.data(forKey: "captchaImageData") {
            self._captchaImageData = State(initialValue: storedCaptcha)
        }
    }
    
    var body: some View {
        if sessionId != nil, userInfo != nil {
            loggedInView
        } else {
            loginView
        }
    }
    
    var loginView: some View {
        VStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                    
                    HStack {
                        TextField("CAPTCHA", text: $captcha)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if isCaptchaLoading {
                            ProgressView()
                        } else if let data = captchaImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 75, height: 30)
                                .cornerRadius(5)
                        }
                    }
                    
                    Button(action: login) {
                        Text("Sign In")
                    }
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                } footer: {
                    Text("All data will only be stored on this device and the TSIMS server. \(connectionStatus)")
                        .font(.caption)
                        .contentMargins(.top, 10)
                }
            }
            .onAppear(perform: {
                // 强制刷新验证码图像和会话
                fetchCaptchaImage()
            })
            .navigationTitle("Sign In")
            .contentMargins(.top, 10.0)
            .toolbar {
                Button(action: fetchCaptchaImage) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
        }
    }
    
    var loggedInView: some View {
        VStack {
            if let userInfo = userInfo {
                Form {
                    Section {
                        HStack {
                            Text("No.")
                                .foregroundStyle(.primary)
                            Text("\(userInfo.tUsername)")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("ID")
                                .foregroundStyle(.primary)
                            Text("\(userInfo.studentid)")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Name")
                                .foregroundStyle(.primary)
                            Text("\(userInfo.studentname) \(userInfo.nickname)")
                                .foregroundStyle(.secondary)
                        }
                        Button(action: { showLogoutConfirmation.toggle() }) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showLogoutConfirmation) {
                            Button("Sign Out", role: .destructive, action: logout)
                            Button("Cancel", role: .cancel) {}
                        }
                    } footer: {
                        Text("All data will only be stored on this device and the TSIMS server. \(connectionStatus)")
                            .font(.caption)
                            .contentMargins(.top, 10)
                    }
                }
                .navigationTitle("Account Details")
                .contentMargins(.vertical, 10.0)
            }
        }
    }
    
    func fetchCaptchaImageIfNeeded() {
        if captchaImageData == nil {
            fetchCaptchaImage()
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
        
        URLSession.shared.dataTask(with: captchaURL) { data, response, _ in
            DispatchQueue.main.async {
                self.isCaptchaLoading = false
                if let data = data {
                    self.captchaImageData = data
                    self.sessionId = self.extractSessionId(from: response)
                } else {
                    self.errorMessage = "Failed to load CAPTCHA."
                }
            }
        }.resume()
    }
    
    func login() {
        print("Username: \(username)")
        print("Password: \(password)")
        print("CAPTCHA: \(captcha)")
        
        guard sessionId != nil else {
            errorMessage = "Session ID is missing."
            return
        }
        
        guard !username.isEmpty, !password.isEmpty, !captcha.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isCaptchaLoading = true
        errorMessage = nil
        
        guard let loginURL = URL(string: "\(Configuration.baseURL)/php/login.php") else {
            self.errorMessage = "Invalid login URL."
            self.isCaptchaLoading = false
            return
        }
        
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers(for: sessionId!)
        request.httpBody = "username=\(username)&password=\(password)&code=\(captcha)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                self.isCaptchaLoading = false
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                do {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    if loginResponse.status != "ok" {
                        self.errorMessage = "Invalid login credentials."
                    } else {
                        self.fetchUserInfo()
                    }
                } catch {
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchUserInfo() {
        guard let infoURL = URL(string: "\(Configuration.baseURL)/php/init_info.php") else {
            self.errorMessage = "Invalid user info URL."
            return
        }
        
        var request = URLRequest(url: infoURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers(for: sessionId)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else {
                    self.errorMessage = "Failed to fetch user info."
                    return
                }
                do {
                    self.userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
                } catch {
                    self.errorMessage = "Failed to parse user info: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func logout() {
        sessionId = nil
        userInfo = nil
        captchaImageData = nil
        fetchCaptchaImage()
    }
    
    func extractSessionId(from response: URLResponse?) -> String? {
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
    
    func headers(for sessionId: String?) -> [String: String]? {
        guard let sessionId = sessionId else { return nil }
        return [
            "Content-Type": "application/x-www-form-urlencoded",
            "Cookie": "PHPSESSID=\(sessionId)"
        ]
    }
}
