import Foundation
import SwiftUI

class AuthenticationService {
    static let shared = AuthenticationService()
    
    private init() {}
    
    func fetchCaptchaImage(completion: @escaping (Result<(Data, String?), Error>) -> Void) {
        guard let captchaURL = URL(string: "\(Configuration.baseURL)/php/login_key.php") else {
            completion(.failure(NSError(domain: "Invalid CAPTCHA URL", code: 400)))
            return
        }
        
        URLSession.shared.dataTask(with: captchaURL) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: 204)))
                    return
                }
                
                // Extract session ID from response
                let sessionId = self.extractSessionId(from: response)
                completion(.success((data, sessionId)))
            }
        }.resume()
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
}