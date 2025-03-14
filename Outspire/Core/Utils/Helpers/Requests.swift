import SwiftUI

func setupRequest(urlString: String, sessionId: String?) -> URLRequest? {
    guard let url = URL(string: urlString) else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    var headers = ["Content-Type": "application/x-www-form-urlencoded"]
    if let sessionId = sessionId {
        headers["Cookie"] = "PHPSESSID=\(sessionId)"
    }
    request.allHTTPHeaderFields = headers
    return request
}

