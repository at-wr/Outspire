import Foundation

class CacheManager {
    static func clearAllCache() {
        let userDefaults = UserDefaults.standard
        
        // Preserve app settings
        let useSSL = Configuration.useSSL
        let hideAcademicScore = Configuration.hideAcademicScore
        
        // Clear club activities cache
        userDefaults.removeObject(forKey: "cachedClubGroups")
        userDefaults.removeObject(forKey: "clubActivitiesCacheTimestamp")
        userDefaults.removeObject(forKey: "selectedClubGroupId")
        
        // Clear academic scores cache
        userDefaults.removeObject(forKey: "cachedTerms")
        userDefaults.removeObject(forKey: "termsCacheTimestamp")
        userDefaults.removeObject(forKey: "selectedTermId")
        
        // Clear pattern-based keys
        for key in userDefaults.dictionaryRepresentation().keys {
            if key.hasPrefix("cachedActivities-") || 
                key.hasPrefix("cachedScores-") || 
                key.hasPrefix("scoresCacheTimestamp-") {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        // Restore preserved settings
        Configuration.useSSL = useSSL
        Configuration.hideAcademicScore = hideAcademicScore
        
        // Remove reference to AddRecordViewModel.cachedFormData - we'll handle this differently
        // instead of directly accessing a private property
        NotificationCenter.default.post(name: Notification.Name("ClearCachedFormData"), object: nil)
    }
}
