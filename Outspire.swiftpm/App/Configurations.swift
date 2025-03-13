import Foundation

struct Configuration {
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
        return useSSL ? "https://my.wrye.dev:47948" : "http://101.230.1.173:6300"
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
        }
    }
    
    static var holidayHasEndDate: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "holidayHasEndDate")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "holidayHasEndDate")
        }
    }
    
    static var holidayEndDate: Date {
        get {
            return UserDefaults.standard.object(forKey: "holidayEndDate") as? Date ?? Date().addingTimeInterval(86400)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "holidayEndDate")
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
}
