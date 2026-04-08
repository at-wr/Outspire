import Foundation

enum Configuration {
    static let appGroupSuiteName = "group.dev.wrye.Outspire"
    // For LLM Service
    // Go to Configuration.local.swift

    static var useSSL: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "useSSL")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useSSL")
        }
    }

    // Feature flag: allow HTTPS relay/proxy usage. Disabled for v0.7 release.
    static var httpsProxyFeatureEnabled: Bool {
        get {
            // Default to false if not set, so the feature is globally disabled in v0.7
            if UserDefaults.standard.object(forKey: "httpsProxyFeatureEnabled") == nil { return false }
            return UserDefaults.standard.bool(forKey: "httpsProxyFeatureEnabled")
        }
        set { UserDefaults.standard.set(newValue, forKey: "httpsProxyFeatureEnabled") }
    }

    // Effective HTTPS relay usage, combining user preference and feature availability
    static var isHttpsProxyEnabled: Bool { httpsProxyFeatureEnabled && useSSL }

    // Toggle: use new TSIMS (v2) server (ASP.NET) instead of legacy PHP backend
    static var useNewTSIMS: Bool {
        get {
            // Default to true if not set to move users to the new server by default
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "useNewTSIMS") == nil { return true }
            return defaults.bool(forKey: "useNewTSIMS")
        }
        set { UserDefaults.standard.set(newValue, forKey: "useNewTSIMS") }
    }

    static var hideAcademicScore: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "hideAcademicScore")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hideAcademicScore")
        }
    }

    static var showMondayClass: Bool {
        get {
            return UserDefaults.standard.object(forKey: "showMondayClass") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "showMondayClass")
        }
    }

    static var showSecondsInLongCountdown: Bool {
        get {
            return UserDefaults.standard.object(forKey: "showSecondsInLongCountdown") as? Bool
                ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "showSecondsInLongCountdown")
        }
    }

    static var showCountdownForFutureClasses: Bool {
        get {
            return UserDefaults.standard.object(forKey: "showCountdownForFutureClasses") as? Bool
                ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "showCountdownForFutureClasses")
        }
    }

    static var selectedDayOverride: Int? {
        get {
            let value = UserDefaults.standard.integer(forKey: "selectedDayOverride")
            return value == -1 ? nil : value
        }
        set {
            UserDefaults.standard.set(newValue ?? -1, forKey: "selectedDayOverride")
        }
    }

    static var setAsToday: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "setAsToday")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "setAsToday")
        }
    }

    static var lastAppLaunchDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: "lastAppLaunchDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastAppLaunchDate")
        }
    }

    static var baseURL: String {
        // return isHttpsProxyEnabled ? "https://easy-tsims.vercel.app" : "http://101.230.1.173:6300"
        return isHttpsProxyEnabled ? "https://tsimsproxy.wrye.dev" : "http://101.230.1.173:6300"
    }

    // Base URL for the new TSIMS server captured from HARs
    static var tsimsV2BaseURL: String {
        return "http://101.227.232.33:8001"
    }

    static var headers: [String: String] = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]

    // MARK: - Connectivity probes (centralized)

    static var directServerProbeURL: String { "http://101.230.1.173:6300/php/login_key.php" }
    static var relayServerProbeURL: String { "https://tsimsproxy.wrye.dev/php/login_key.php" }

    // MARK: - LLM configuration

    static var llmModel: String { "grok/grok-3-latest" }

    static var isHolidayMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isHolidayMode")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isHolidayMode")
            NotificationCenter.default.post(name: .holidayModeDidChange, object: nil)
        }
    }

    // Feature disablement flags while migrating to new TSIMS
    // These are force-disabled when using new TSIMS until endpoints are finalized
    static var disableNoticesAttendanceExamsInNewTSIMS: Bool { true }

    static var holidayHasEndDate: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "holidayHasEndDate")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "holidayHasEndDate")
            NotificationCenter.default.post(name: .holidayModeDidChange, object: nil)
        }
    }

    static var holidayEndDate: Date {
        get {
            return UserDefaults.standard.object(forKey: "holidayEndDate") as? Date
                ?? Date().addingTimeInterval(86400)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "holidayEndDate")
            NotificationCenter.default.post(name: .holidayModeDidChange, object: nil)
        }
    }

    // Debug: verbose network logging for TSIMS v2
    static var debugNetworkLogging: Bool {
        get {
            if UserDefaults.standard.object(forKey: "debugNetworkLogging") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "debugNetworkLogging")
        }
        set { UserDefaults.standard.set(newValue, forKey: "debugNetworkLogging") }
    }

    //// Add setting for AI suggestion disclaimer flags
    // static func resetAIDisclaimers() {
    //    DisclaimerManager.shared.resetDisclaimers()
    // }
}
