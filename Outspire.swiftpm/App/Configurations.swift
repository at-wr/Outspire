import Foundation

struct Configuration {
    static var useSSL: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "useSSL")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useSSL")
        }
    }
    
    static var hideAcademicScore: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "hideAcademicScore")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hideAcademicScore")
        }
    }
    
    static var baseURL: String {
        return useSSL ? "https://easy-tsims.vercel.app" : "http://101.230.1.173:6300"
    }
    
    static var headers: [String: String] = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
}
