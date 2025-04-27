import Foundation

struct Configuration {
    static var departureNotificationsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "departureNotificationsEnabled") == nil {
                return false // Default: disabled
            }
            return UserDefaults.standard.bool(forKey: "departureNotificationsEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "departureNotificationsEnabled")
        }
    }
    
    static var departureNotificationTime: Date {
        get {
            if let storedTime = UserDefaults.standard.object(forKey: "departureNotificationTime") as? Date {
                return storedTime
            } else {
                // Default time: 6:55 AM
                var components = DateComponents()
                components.hour = 6
                components.minute = 55
                return Calendar.current.date(from: components) ?? Date()
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "departureNotificationTime")
        }
    }

    static var useSSL: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "useSSL")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useSSL")
        }
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
            return UserDefaults.standard.object(forKey: "showSecondsInLongCountdown") as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "showSecondsInLongCountdown")
        }
    }

    static var showCountdownForFutureClasses: Bool {
        get {
            return UserDefaults.standard.object(forKey: "showCountdownForFutureClasses") as? Bool ?? false
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
        // return useSSL ? "https://easy-tsims.vercel.app" : "http://101.230.1.173:6300"
        return useSSL ? "https://tsimsproxy.wrye.dev" : "http://101.230.1.173:6300"
    }

    static var headers: [String: String] = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]

    static var isHolidayMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isHolidayMode")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isHolidayMode")
            NotificationCenter.default.post(name: .holidayModeDidChange, object: nil)
        }
    }

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
            return UserDefaults.standard.object(forKey: "holidayEndDate") as? Date ?? Date().addingTimeInterval(86400)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "holidayEndDate")
            NotificationCenter.default.post(name: .holidayModeDidChange, object: nil)
        }
    }

    // Add new debug configuration options
    static var debugOverrideMapView: Bool {
        get { UserDefaults.standard.bool(forKey: "debugOverrideMapView") }
        set { UserDefaults.standard.set(newValue, forKey: "debugOverrideMapView") }
    }

    static var debugShowMapView: Bool {
        get { UserDefaults.standard.bool(forKey: "debugShowMapView") }
        set { UserDefaults.standard.set(newValue, forKey: "debugShowMapView") }
    }

    // Add new setting for manually hiding map
    static var manuallyHideMapAtSchool: Bool {
        get { UserDefaults.standard.bool(forKey: "manuallyHideMapAtSchool") }
        set { UserDefaults.standard.set(newValue, forKey: "manuallyHideMapAtSchool") }
    }

    // Add new setting for automatic Live Activities
    static var automaticallyStartLiveActivities: Bool {
        get {
            if UserDefaults.standard.object(forKey: "automaticallyStartLiveActivities") == nil {
                return true // Default: enabled
            }
            return UserDefaults.standard.bool(forKey: "automaticallyStartLiveActivities")
        }
        set { UserDefaults.standard.set(newValue, forKey: "automaticallyStartLiveActivities") }
    }
}
