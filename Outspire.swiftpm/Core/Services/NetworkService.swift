import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case requestFailed(Error)
    case serverError(Int)
    case unauthorized
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    // Generic request function that infers type from completion handler
    func request<T>(
        endpoint: String,
        method: HTTPMethod = .post,
        parameters: [String: String]? = nil,
        sessionId: String? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) where T: Decodable {
        guard let url = URL(string: "\(Configuration.baseURL)/php/\(endpoint)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        var headers = ["Content-Type": "application/x-www-form-urlencoded"]
        if let sessionId = sessionId {
            headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = headers
        
        if let parameters = parameters {
            let paramString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = paramString.data(using: .utf8)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.requestFailed(error)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, 
                   httpResponse.statusCode >= 400 {
                    completion(.failure(.serverError(httpResponse.statusCode)))
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    print("Decoding error: \(error)")
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
}
