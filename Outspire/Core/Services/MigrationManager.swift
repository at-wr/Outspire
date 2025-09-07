import Foundation
import SwiftUI

/// Handles one-time migrations that impact authentication state across versions.
/// For v0.7 and later, force users upgrading from older versions to re-sign in
/// by clearing legacy PHP sessions and TSIMS v2 credentials/cookies.
@MainActor
final class MigrationManager {
    static let shared = MigrationManager()
    private init() {}

    private let migrationFlagKey = "didForceReauth_v0_7"
    private let lastVersionKey = "lastVersionRun" // reused if present

    func performAuthMigrationIfNeeded() {
        // Avoid repeating once performed
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: migrationFlagKey) { return }

        // Determine current app version (CFBundleShortVersionString)
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return
        }

        // Only apply on 0.7.0+ binaries
        guard currentVersion.compare("0.7", options: .numeric) != .orderedAscending else { return }

        // Only force reauth for upgrades from versions prior to 0.7
        // If we have a recorded lastVersionRun and it's < 0.7, migrate.
        if let lastVersion = defaults.string(forKey: lastVersionKey) {
            let needsMigration = lastVersion.compare("0.7", options: .numeric) == .orderedAscending
            if !needsMigration { return }
        } else {
            // If no recorded version, heuristically detect upgrade from legacy by presence of legacy session
            let hasLegacySessionId = defaults.string(forKey: "sessionId")?.isEmpty == false
            let hasLegacyCookie = (HTTPCookieStorage.shared.cookies ?? []).contains { $0.name == "PHPSESSID" }
            if !(hasLegacySessionId || hasLegacyCookie) {
                // Looks like a fresh install; skip
                return
            }
        }

        // Perform migration: clear legacy + v2 auth
        forceSignOutAllAuthStates()

        // Mark done to avoid repeating
        defaults.set(true, forKey: migrationFlagKey)
    }

    private func forceSignOutAllAuthStates() {
        // 1) Legacy PHP session: use existing logout routine for comprehensive cleanup
        SessionService.shared.logoutUser()

        // 2) TSIMS v2: remove persisted user info and credentials
        UserDefaults.standard.removeObject(forKey: "v2User")
        SecureStore.remove("v2.username")
        SecureStore.remove("v2.password")

        // Mark v2 unauthenticated in-memory
        AuthServiceV2.shared.isAuthenticated = false

        // 3) Purge cookies and reset URLSession to avoid stale auth
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies { HTTPCookieStorage.shared.deleteCookie(cookie) }
        }
        URLSession.shared.reset {}

        // 4) Ensure all caches are cleared
        CacheManager.clearAllCache()

        // 5) Forcefully disable HTTPS relay/proxy for v0.7
        Configuration.useSSL = false
        Configuration.httpsProxyFeatureEnabled = false
    }
}
