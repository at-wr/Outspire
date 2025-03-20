import Foundation
import SwiftUI

/// Handles URL scheme navigation for deep linking in Outspire
class URLSchemeHandler: ObservableObject {
    static let shared = URLSchemeHandler()
    
    // Published properties to trigger navigation
    @Published var navigateToToday = false
    @Published var navigateToClassTable = false
    @Published var navigateToClub: String? = nil
    @Published var navigateToAddActivity: String? = nil
    
    // Add a property to signal that sheets should be closed
    @Published var closeAllSheets = false
    
    // Error alert control
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    private init() {}
    
    /// Process an incoming URL to determine navigation path
    /// - Parameter url: The URL to process
    /// - Returns: True if the URL was successfully handled
    func handleURL(_ url: URL) -> Bool {
        print("Processing URL: \(url.absoluteString)")
        guard url.scheme == "outspire" else { return false }
        
        // Signal that sheets should be closed when handling a URL
        closeAllSheets = true
        
        // Reset any previous navigation states except the current URL we're processing
        resetNavigationStatesExceptCurrent()
        
        // Get the path components after the host
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        // Reset closeAllSheets after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.closeAllSheets = false
        }
        
        switch host {
        case "today":
            navigateToToday = true
            return true
            
        case "classtable":
            navigateToClassTable = true
            return true
            
        case "club":
            if pathComponents.count >= 1 {
                let clubId = pathComponents[0]
                print("URL Handler found club ID: \(clubId)")
                
                // If we're already navigating to the same club, don't reset
                if navigateToClub != clubId {
                    // Remove any previous club ID first to ensure the change is detected
                    navigateToClub = nil
                    
                    // Use a slight delay to ensure the nil change is processed first
                    DispatchQueue.main.async {
                        self.navigateToClub = clubId
                    }
                }
                return true
            } else {
                showError("Invalid club URL: missing club ID")
                return false
            }
            
        case "addactivity":
            if pathComponents.count >= 1 {
                let clubId = pathComponents[0]
                navigateToAddActivity = clubId
                return true
            } else {
                showError("Invalid activity URL: missing club ID")
                return false
            }
            
        default:
            showError("Unsupported URL path: \(host)")
            return false
        }
    }
    
    /// Reset all navigation state triggers
    private func resetNavigationStates() {
        navigateToToday = false
        navigateToClassTable = false
        navigateToClub = nil
        navigateToAddActivity = nil
    }
    
    /// Reset navigation states except for the current URL being processed
    private func resetNavigationStatesExceptCurrent() {
        navigateToToday = false
        navigateToClassTable = false
        // We don't reset navigateToClub here because it will be set correctly in the case statements
        navigateToAddActivity = nil
    }
    
    /// Show an error alert with the given message
    /// - Parameter message: Error message to display
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

// Extension to handle URL validation
extension URLSchemeHandler {
    /// Creates a valid deep link URL for the app
    /// - Parameters:
    ///   - path: The path component (e.g., "today", "club/123")
    ///   - queryItems: Optional query parameters
    /// - Returns: A formatted URL or nil if invalid
    static func createDeepLink(path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "outspire"
        
        // Split path into host and path components
        let pathParts = path.split(separator: "/", maxSplits: 1)
        if pathParts.isEmpty { return nil }
        
        components.host = String(pathParts[0])
        
        if pathParts.count > 1 {
            components.path = "/\(pathParts[1])"
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        return components.url
    }
}
