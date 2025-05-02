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

        // Clear school arrangements cache
        userDefaults.removeObject(forKey: "cachedSchoolArrangements")
        userDefaults.removeObject(forKey: "cachedSchoolArrangements-timestamp")

        // Clear pattern-based keys
        for key in userDefaults.dictionaryRepresentation().keys {
            if key.hasPrefix("cachedActivities-") ||
                key.hasPrefix("cachedScores-") ||
                key.hasPrefix("scoresCacheTimestamp-") ||
                key.hasPrefix("cachedSchoolArrangementDetail-") {
                userDefaults.removeObject(forKey: key)
                userDefaults.removeObject(forKey: "\(key)-timestamp")
            }
        }

        // Restore preserved settings
        Configuration.useSSL = useSSL
        Configuration.hideAcademicScore = hideAcademicScore

        // Remove reference to AddRecordViewModel.cachedFormData - we'll handle this differently
        // instead of directly accessing a private property
        NotificationCenter.default.post(name: Notification.Name("ClearCachedFormData"), object: nil)
    }

    // Clear only club activities related cache
    static func clearClubActivitiesCache() {
        let userDefaults = UserDefaults.standard

        userDefaults.removeObject(forKey: "cachedClubGroups")
        userDefaults.removeObject(forKey: "clubActivitiesCacheTimestamp")
        userDefaults.removeObject(forKey: "selectedClubGroupId")

        // Clear all cached activities but preserve the groups list
        for key in userDefaults.dictionaryRepresentation().keys {
            if key.hasPrefix("cachedActivities-") {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}
