import Foundation
import OSLog

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

/// A service that handles all network requests to the TSIMS API.
///
/// This class provides methods for making HTTP requests and handling responses.
/// It includes functionality for managing session cookies, handling parameters,
/// and decoding JSON responses.
class NetworkService {
    static let shared = NetworkService()

    // Allow dependency injection for tests
    private var session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    #if DEBUG
    func setSession(_ session: URLSession) { self.session = session }
    #endif

    // Form URL encoding allowed characters - stricter than .urlQueryAllowed
    private static let formURLEncodedAllowedCharacters: CharacterSet = {
        // Start with the URL query allowed characters
        var allowed = CharacterSet.urlQueryAllowed

        // Remove characters that need special encoding in form submissions
        allowed.remove(charactersIn: "!*'();:@&=+$,/?%#[]")

        return allowed
    }()

    /// Performs a network request with optional parameters and session ID
    /// - Parameters:
    ///   - endpoint: The API endpoint path
    ///   - method: The HTTP method to use (default: .post)
    ///   - parameters: Optional URL parameters to include in the request
    ///   - sessionId: Optional session ID for authentication
    ///   - completion: Closure called with the result of the network request
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

        // Track if we're using SSL for this request (to check connection if it fails)
        let isUsingSSL = Configuration.isHttpsProxyEnabled

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 10.0 // Add a default timeout of 10 seconds

        var headers = ["Content-Type": "application/x-www-form-urlencoded"]
        if let sessionId = sessionId {
            headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = headers

        if let parameters = parameters {
            // URL-encode parameter values with stricter encoding for form submissions
            let paramString = parameters.map { key, value -> String in
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: Self.formURLEncodedAllowedCharacters) ?? value
                return "\(key)=\(encodedValue)"
            }.joined(separator: "&")

            request.httpBody = paramString.data(using: .utf8)
        }

        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Handle connection error
                    Log.net.error("Network request failed: \(error.localizedDescription, privacy: .public)")

                    // Check if this is a timeout or connectivity issue
                    let nsError = error as NSError
                    if nsError.domain == NSURLErrorDomain &&
                        (nsError.code == NSURLErrorTimedOut ||
                            nsError.code == NSURLErrorCannotConnectToHost ||
                            nsError.code == NSURLErrorNetworkConnectionLost ||
                            nsError.code == NSURLErrorNotConnectedToInternet) {
                        // This is a connectivity issue - check if we should switch servers
                        ConnectivityManager.shared.handleNetworkRequestFailure(wasUsingSSL: isUsingSSL)
                    }

                    completion(.failure(.requestFailed(error)))
                    return
                }

                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode >= 400 {
                    // Server error - also check connectivity if this is a serious server error
                    if httpResponse.statusCode >= 500 {
                        ConnectivityManager.shared.handleNetworkRequestFailure(wasUsingSSL: isUsingSSL)
                    }
                    completion(.failure(.serverError(httpResponse.statusCode)))
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    Log.net.error("Decoding error: \(String(describing: error), privacy: .public)")
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    // MARK: - Async/Await variant (non-breaking addition)
    @available(iOS 15.0, macOS 12.0, *)
    func requestAsync<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .post,
        parameters: [String: String]? = nil,
        sessionId: String? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(Configuration.baseURL)/php/\(endpoint)") else {
            throw NetworkError.invalidURL
        }

        let isUsingSSL = Configuration.isHttpsProxyEnabled

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 10.0

        var headers = ["Content-Type": "application/x-www-form-urlencoded"]
        if let sessionId = sessionId { headers["Cookie"] = "PHPSESSID=\(sessionId)" }
        request.allHTTPHeaderFields = headers

        if let parameters = parameters {
            let paramString = parameters.map { key, value -> String in
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: Self.formURLEncodedAllowedCharacters) ?? value
                return "\(key)=\(encodedValue)"
            }.joined(separator: "&")
            request.httpBody = paramString.data(using: .utf8)
        }

        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                if http.statusCode >= 500 {
                    await MainActor.run { ConnectivityManager.shared.handleNetworkRequestFailure(wasUsingSSL: isUsingSSL) }
                }
                throw NetworkError.serverError(http.statusCode)
            }
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain &&
                (nsError.code == NSURLErrorTimedOut ||
                 nsError.code == NSURLErrorCannotConnectToHost ||
                 nsError.code == NSURLErrorNetworkConnectionLost ||
                 nsError.code == NSURLErrorNotConnectedToInternet) {
                await MainActor.run { ConnectivityManager.shared.handleNetworkRequestFailure(wasUsingSSL: isUsingSSL) }
            }
            if let netErr = error as? NetworkError { throw netErr }
            throw NetworkError.requestFailed(error)
        }
    }

    // Legacy reflection API removed (migrated to CASServiceV2)
}
