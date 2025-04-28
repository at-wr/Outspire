import Foundation
import Network
import SwiftUI

class ConnectivityManager: ObservableObject {
    static let shared = ConnectivityManager()
    
    // Published properties
    @Published var isInternetAvailable = true
    @Published var isCheckingConnectivity = false
    
    // Alert control
    @Published var showRelayAlert = false
    @Published var showDirectAlert = false
    @Published var showNoInternetAlert = false
    
    // Onboarding awareness
    private var isOnboardingActive = false
    
    // Private state
    private var networkMonitor: NWPathMonitor?
    private var directServerMonitor: Timer?
    private var relayServerMonitor: Timer?
    
    // Check tracking
    private var directCheckCompleted = false
    private var relayCheckCompleted = false
    
    // Configuration
    private let directServerURL = "http://101.230.1.173:6300/php/login_key.php"
    private let relayServerURL = "https://tsimsproxy.wrye.dev/php/login_key.php"
    private let checkInterval: TimeInterval = 300 // 5 minutes
    private let timeoutInterval: TimeInterval = 5.0 // 5 seconds timeout
    
    // State tracking
    private var isUsingTemporaryRelay = false
    private var hasSuggestedRelay = false
    private var hasSuggestedDirect = false
    private var directServerAccessible = false
    private var relayServerAccessible = false
    
    private init() {
        // Start with a true value to avoid incorrect alert until we've checked
        directServerAccessible = true
        relayServerAccessible = true
        
        // Check if onboarding is active (has not been completed)
        isOnboardingActive = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        setupNetworkMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Onboarding Management
    
    /// Call this method when onboarding begins
    func setOnboardingActive(_ active: Bool) {
        isOnboardingActive = active
        
        // Clear any pending alerts if onboarding becomes active
        if active {
            DispatchQueue.main.async {
                self.showRelayAlert = false
                self.showDirectAlert = false
                self.showNoInternetAlert = false
            }
        }
    }
    
    /// Check if onboarding is active
    func isInOnboarding() -> Bool {
        return isOnboardingActive
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        setupNetworkMonitoring()
        scheduleServerChecks()
        
        // Do an immediate check on startup
        checkConnectivity(forceCheck: true)
    }
    
    func stopMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
        directServerMonitor?.invalidate()
        directServerMonitor = nil
        relayServerMonitor?.invalidate()
        relayServerMonitor = nil
    }
    
    func checkConnectivity(forceCheck: Bool = false) {
        // Don't check if already checking, unless forced
        if isCheckingConnectivity && !forceCheck {
            return
        }
        
        DispatchQueue.main.async {
            self.isCheckingConnectivity = true
        }
        
        // Reset check tracking flags
        directCheckCompleted = false
        relayCheckCompleted = false
        
        // Check both servers concurrently
        checkDirectServerAccess { [weak self] isAccessible in
            guard let self = self else { return }
            self.directServerAccessible = isAccessible
            self.directCheckCompleted = true
            self.tryEvaluateConnectivityStatus()
        }
        
        checkRelayServerAccess { [weak self] isAccessible in
            guard let self = self else { return }
            self.relayServerAccessible = isAccessible
            self.relayCheckCompleted = true
            self.tryEvaluateConnectivityStatus()
        }
    }
    
    func userSelectedRelay() {
        // User explicitly chose to use relay
        DispatchQueue.main.async {
            if !Configuration.useSSL {
                Configuration.useSSL = true
                self.isUsingTemporaryRelay = true
            }
            self.showRelayAlert = false
            self.hasSuggestedRelay = true
        }
    }
    
    func userDismissedRelayPrompt() {
        // User declined to use relay
        DispatchQueue.main.async {
            self.showRelayAlert = false
            self.hasSuggestedRelay = true
        }
    }
    
    func userSelectedDirect() {
        // User explicitly chose to use direct connection
        DispatchQueue.main.async {
            if Configuration.useSSL {
                Configuration.useSSL = false
                self.isUsingTemporaryRelay = false
            }
            self.showDirectAlert = false
            self.hasSuggestedDirect = true
        }
    }
    
    func userDismissedDirectPrompt() {
        // User declined to use direct connection
        DispatchQueue.main.async {
            self.showDirectAlert = false
            self.hasSuggestedDirect = true
        }
    }
    
    func userToggledRelay(isEnabled: Bool) {
        // User manually toggled the setting
        DispatchQueue.main.async {
            Configuration.useSSL = isEnabled
            self.isUsingTemporaryRelay = false  // Clear temporary flag since this was manual
            self.hasSuggestedRelay = false      // Reset suggestion flags
            self.hasSuggestedDirect = false
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        guard networkMonitor == nil else { return }
        
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isInternetAvailable = path.status == .satisfied
                
                // If internet just became available, check connectivity
                if path.status == .satisfied {
                    self?.checkConnectivity()
                } else {
                    // If internet is lost, show no internet alert
                    self?.showNoInternetAlert = true
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitoring")
        networkMonitor?.start(queue: queue)
    }
    
    private func scheduleServerChecks() {
        // Cancel existing timers
        directServerMonitor?.invalidate()
        relayServerMonitor?.invalidate()
        
        // Schedule periodic checks
        directServerMonitor = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkConnectivity()
        }
        
        // Perform an initial check
        checkConnectivity()
    }
    
    private func checkDirectServerAccess(completion: @escaping (Bool) -> Void) {
        checkServerAccess(urlString: directServerURL) { isAccessible in
            completion(isAccessible)
        }
    }
    
    private func checkRelayServerAccess(completion: @escaping (Bool) -> Void) {
        checkServerAccess(urlString: relayServerURL) { isAccessible in
            completion(isAccessible)
        }
    }
    
    private func checkServerAccess(urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval
        request.httpMethod = "HEAD"  // Just check headers, no need for full response
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        // Add a backup timeout to ensure we don't get stuck if no response
        let backupTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval + 1.0, repeats: false) { _ in
            print("Backup timeout triggered for \(urlString)")
            completion(false)
        }
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            // Cancel the backup timer as we got a response
            backupTimer.invalidate()
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Server access check failed: \(urlString), error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response from: \(urlString)")
                    completion(false)
                    return
                }
                
                // Consider any response (even 4xx or 5xx) as accessible
                // We just want to know if the server is reachable
                print("Server \(urlString) responded with code: \(httpResponse.statusCode)")
                completion(true)
            }
        }
        
        task.resume()
    }
    
    private func tryEvaluateConnectivityStatus() {
        // Only proceed when both server checks have reported back
        if directCheckCompleted && relayCheckCompleted {
            evaluateConnectivityStatus()
        }
    }
    
    private func evaluateConnectivityStatus() {
        // We now know both checks are complete, so log connectivity status
        print("Connectivity check complete: Direct=\(directServerAccessible), Relay=\(relayServerAccessible), UsingSSL=\(Configuration.useSSL), UsingTemporaryRelay=\(isUsingTemporaryRelay)")
        
        // First check if we have internet connectivity at all
        if !isInternetAvailable {
            print("No internet connection detected")
            if !isOnboardingActive {
                DispatchQueue.main.async {
                    self.showNoInternetAlert = true
                }
            }
            DispatchQueue.main.async {
                self.isCheckingConnectivity = false
            }
            return
        }
        
        // Decision tree for suggesting relay or direct connection
        if directServerAccessible && relayServerAccessible {
            // Both servers are accessible
            if isUsingTemporaryRelay && !hasSuggestedDirect {
                // We're using temporary relay but direct is available - suggest switching back
                print("Suggesting switch back to direct connection")
                if !isOnboardingActive {
                    DispatchQueue.main.async {
                        self.showDirectAlert = true
                    }
                }
            }
        } else if !directServerAccessible && relayServerAccessible {
            // Only relay is accessible
            if !Configuration.useSSL && !hasSuggestedRelay {
                // We're not using relay but direct is inaccessible - suggest switching to relay
                print("Suggesting switch to relay connection")
                if !isOnboardingActive {
                    DispatchQueue.main.async {
                        self.showRelayAlert = true
                    }
                }
            }
        } else if directServerAccessible && !relayServerAccessible {
            // Only direct is accessible
            if Configuration.useSSL && isUsingTemporaryRelay {
                // We're using temporary relay but it's not accessible and direct is - switch back
                print("Automatically switching back to direct connection")
                DispatchQueue.main.async {
                    Configuration.useSSL = false
                    self.isUsingTemporaryRelay = false
                }
            }
        } else {
            // Neither server is accessible
            print("Both connections are inaccessible")
            // Show no internet alert if neither server is accessible
            if isInternetAvailable {
                // We have internet but can't reach either server
                print("Internet available but can't reach either server")
            } else {
                // No internet connection
                print("No internet connection")
                if !isOnboardingActive {
                    DispatchQueue.main.async {
                        self.showNoInternetAlert = true
                    }
                }
            }
        }
        
        // Reset checking flag
        DispatchQueue.main.async {
            self.isCheckingConnectivity = false
        }
    }
    
    // MARK: - Network Request Tracking
    
    /// Call this method when a network request times out or fails
    func handleNetworkRequestFailure(wasUsingSSL: Bool) {
        // If a request fails and we're using the same connection type that was used for the request,
        // check connectivity to see if we should switch
        if wasUsingSSL == Configuration.useSSL {
            checkConnectivity(forceCheck: true)
        }
    }
}