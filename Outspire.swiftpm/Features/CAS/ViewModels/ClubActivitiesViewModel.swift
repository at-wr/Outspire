import SwiftUI

class ClubActivitiesViewModel: ObservableObject {
    @Published var groups: [ClubGroup] = []
    @Published var activities: [ActivityRecord] = []
    @Published var selectedGroupId: String = ""
    @Published var errorMessage: String?
    @Published var isLoadingGroups: Bool = false
    @Published var isLoadingActivities: Bool = false
    @Published var showingDeleteConfirmation = false
    @Published var recordToDelete: ActivityRecord?
    private var hasAttemptedInitialLoad = false
    
    // Cache-related properties
    private var cachedActivities: [String: [ActivityRecord]] = [:]
    private let cacheTimestampKey = "clubActivitiesCacheTimestamp"
    private let cacheDuration: TimeInterval = 300 // 5 minutes cache validity
    
    private let sessionService = SessionService.shared
    
    init() {
        // Load cached groups on init if available
        if let cachedGroupsData = UserDefaults.standard.data(forKey: "cachedClubGroups"),
           let groups = try? JSONDecoder().decode([ClubGroup].self, from: cachedGroupsData) {
            self.groups = groups
            
            // Select the previously selected group id if available
            if let savedGroupId = UserDefaults.standard.string(forKey: "selectedClubGroupId") {
                self.selectedGroupId = savedGroupId
                
                // Load cached activities for this group if available
                loadCachedActivities(for: savedGroupId)
            } else if let firstGroup = groups.first {
                self.selectedGroupId = firstGroup.C_GroupsID
            }
        }
    }
    
    private func loadCachedActivities(for groupId: String) {
        if let cachedData = UserDefaults.standard.data(forKey: "cachedActivities-\(groupId)"),
           let activities = try? JSONDecoder().decode([ActivityRecord].self, from: cachedData) {
            self.activities = activities
        }
    }
    
    private func cacheActivities(for groupId: String, activities: [ActivityRecord]) {
        if let encodedData = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encodedData, forKey: "cachedActivities-\(groupId)")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        }
    }
    
    private func cacheGroups(_ groups: [ClubGroup]) {
        if let encodedData = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encodedData, forKey: "cachedClubGroups")
        }
    }
    
    func isCacheValid() -> Bool {
        let lastUpdate = UserDefaults.standard.double(forKey: cacheTimestampKey)
        let currentTime = Date().timeIntervalSince1970
        return (currentTime - lastUpdate) < cacheDuration
    }
    
    // Async version for refreshable support
    @MainActor
    func fetchGroupsAsync(forceRefresh: Bool = false) async {
        await withCheckedContinuation { continuation in
            fetchGroups(forceRefresh: forceRefresh)
            continuation.resume()
        }
    }
    
    // Async version for refreshable support
    @MainActor
    func fetchActivityRecordsAsync(forceRefresh: Bool = false) async {
        await withCheckedContinuation { continuation in
            fetchActivityRecords(forceRefresh: forceRefresh)
            continuation.resume()
        }
    }
    
    func fetchGroups(forceRefresh: Bool = false) {
        // If we have cached data and not forcing a refresh, don't fetch
        if !forceRefresh && !groups.isEmpty {
            return
        }
        
        guard !isLoadingGroups else { return }
        
        isLoadingGroups = true
        errorMessage = nil
        
        NetworkService.shared.request(
            endpoint: "cas_add_mygroups_dropdown.php",
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<GroupDropdownResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoadingGroups = false
                self.hasAttemptedInitialLoad = true
                
                switch result {
                case .success(let response):
                    self.groups = response.groups
                    self.cacheGroups(response.groups)
                    
                    if self.selectedGroupId.isEmpty, let firstGroup = self.groups.first {
                        self.selectedGroupId = firstGroup.C_GroupsID
                        UserDefaults.standard.set(firstGroup.C_GroupsID, forKey: "selectedClubGroupId")
                        self.fetchActivityRecords()
                    } else if !self.selectedGroupId.isEmpty {
                        // If we already had a selected group (from cache), fetch its activities
                        self.fetchActivityRecords()
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load groups: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchActivityRecords(forceRefresh: Bool = false) {
        guard !selectedGroupId.isEmpty else {
            errorMessage = "Please select a group."
            return
        }
        
        // If we're not forcing a refresh and we're already loading, return
        if !forceRefresh && isLoadingActivities {
            return
        }
        
        // If we have cached activities and cache is still valid, use them unless force refresh
        if !forceRefresh && isCacheValid() {
            loadCachedActivities(for: selectedGroupId)
            // Still fetch in background to update cache
        }
        
        isLoadingActivities = true
        errorMessage = nil
        
        // Store the selected group ID
        UserDefaults.standard.set(selectedGroupId, forKey: "selectedClubGroupId")
        
        let parameters = ["groupid": selectedGroupId]
        
        NetworkService.shared.request(
            endpoint: "cas_add_record_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<ActivityResponse, NetworkError>) in
            guard let self = self else { return }
            
            // Use a slightly longer minimum delay to ensure smooth transitions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.isLoadingActivities = false
                
                switch result {
                case .success(let response):
                    withAnimation {
                        self.activities = response.casRecord
                        self.cacheActivities(for: self.selectedGroupId, activities: response.casRecord)
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load activities: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteRecord(record: ActivityRecord) {
        let parameters = ["recordid": record.C_ARecordID]
        errorMessage = nil
        
        // Add haptic feedback
        HapticManager.shared.playFeedback(.medium)
        
        NetworkService.shared.request(
            endpoint: "cas_delete_record_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[String: String], NetworkError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response["status"] == "ok" {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.activities.removeAll { $0.C_ARecordID == record.C_ARecordID }
                        // Update cache after deletion
                        self.cacheActivities(for: self.selectedGroupId, activities: self.activities)
                        self.errorMessage = "Record deleted successfully"
                        
                        // Auto-dismiss the success message after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                if self.errorMessage == "Record deleted successfully" {
                                    self.errorMessage = nil
                                }
                            }
                        }
                    }
                } else {
                    self.errorMessage = response["status"] ?? "Unknown error"
                }
            case .failure(let error):
                self.errorMessage = "Failed to delete record: \(error.localizedDescription)"
            }
        }
    }
    
    func copyActivityToClipboard(_ activity: ActivityRecord) {
        // Add haptic feedback for better user experience
        HapticManager.shared.playFeedback(.light)
        
        let activityInfo = """
        Theme: \(activity.C_Theme)
        Date: \(activity.C_Date)
        Duration: C: \(activity.C_DurationC), A: \(activity.C_DurationA), S: \(activity.C_DurationS)
        Reflection: \(activity.C_Reflection)
        """
        UIPasteboard.general.string = activityInfo
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            errorMessage = "Activity copied to clipboard!"
        }
        
        // Auto-dismiss the message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                if self?.errorMessage == "Activity copied to clipboard!" {
                    self?.errorMessage = nil
                }
            }
        }
    }
}