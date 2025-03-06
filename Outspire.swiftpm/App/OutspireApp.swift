import SwiftUI

@main
struct OutspireApp: App {
    @StateObject private var sessionService = SessionService.shared
    
    init() {
        // Initialize app settings
        if UserDefaults.standard.object(forKey: "useSSL") == nil {
            Configuration.useSSL = false
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavSplitView()
                .environmentObject(sessionService)
        }
    }
}
