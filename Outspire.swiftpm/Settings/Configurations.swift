import SwiftUI

struct Configuration {
    static var useSSL = false
    
    static var baseURL: String {
        return useSSL ? "https://easy-tsims.vercel.app" : "http://101.230.1.173:6300"
    }
    
    static var headers: [String: String] = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
}
