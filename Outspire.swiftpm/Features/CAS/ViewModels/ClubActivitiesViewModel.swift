import SwiftUI

class ClubActivitiesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var groups: [ClubGroup] = []
    @Published var activities: [ActivityRecord] = []
    @Published var selectedGroupId: String = ""
    @Published var errorMessage: String?
    @Published var isLoadingGroups: Bool = false
    @Published var isLoadingActivities: Bool = false
    @Published var showingDeleteConfirmation = false
    @Published var recordToDelete: ActivityRecord?
    
    // MARK: - Private Properties
    private var hasAttemptedInitialLoad = false
    private var cachedActivities: [String: [ActivityRecord]] = [:]
    private let cacheTimestampKey = "clubActivitiesCacheTimestamp"
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    private let sessionService = SessionService.shared
    
    // MARK: - Initialization
    init() {
        loadInitialCachedData()
    }
    
    private func loadInitialCachedData() {
        guard let cachedGroupsData = UserDefaults.standard.data(forKey: "cachedClubGroups"),
              let decodedGroups = try? JSONDecoder().decode([ClubGroup].self, from: cachedGroupsData) else {
            return
        }
        
        self.groups = decodedGroups
        
        if let savedGroupId = UserDefaults.standard.string(forKey: "selectedClubGroupId") {
            self.selectedGroupId = savedGroupId
            loadCachedActivities(for: savedGroupId)
        } else if let firstGroup = decodedGroups.first {
            self.selectedGroupId = firstGroup.C_GroupsID
        }
    }
    
    // MARK: - Cache Management
    private func loadCachedActivities(for groupId: String) {
        guard let cachedData = UserDefaults.standard.data(forKey: "cachedActivities-\(groupId)"),
              let decodedActivities = try? JSONDecoder().decode([ActivityRecord].self, from: cachedData) else {
            return
        }
        self.activities = decodedActivities
    }
    
    private func cacheActivities(for groupId: String, activities: [ActivityRecord]) {
        guard let encodedData = try? JSONEncoder().encode(activities) else { return }
        UserDefaults.standard.set(encodedData, forKey: "cachedActivities-\(groupId)")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
    }
    
    private func cacheGroups(_ groups: [ClubGroup]) {
        guard let encodedData = try? JSONEncoder().encode(groups) else { return }
        UserDefaults.standard.set(encodedData, forKey: "cachedClubGroups")
    }
    
    func isCacheValid() -> Bool {
        let lastUpdate = UserDefaults.standard.double(forKey: cacheTimestampKey)
        let currentTime = Date().timeIntervalSince1970
        return (currentTime - lastUpdate) < cacheDuration
    }
    
    // MARK: - Network Operations
    @MainActor
    func fetchGroupsAsync(forceRefresh: Bool = false) async {
        await withCheckedContinuation { continuation in
            fetchGroups(forceRefresh: forceRefresh)
            continuation.resume()
        }
    }
    
    @MainActor
    func fetchActivityRecordsAsync(forceRefresh: Bool = false) async {
        await withCheckedContinuation { continuation in
            fetchActivityRecords(forceRefresh: forceRefresh)
            continuation.resume()
        }
    }
    
    func fetchGroups(forceRefresh: Bool = false) {
        if !forceRefresh && !groups.isEmpty { return }
        guard !isLoadingGroups else { return }
        
        isLoadingGroups = true
        errorMessage = nil
        
        performGroupsRequest()
    }
    
    private func performGroupsRequest() {
        NetworkService.shared.request(
            endpoint: "cas_add_mygroups_dropdown.php",
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<GroupDropdownResponse, NetworkError>) in
            self?.handleGroupsResponse(result)
        }
    }
    
    private func handleGroupsResponse(_ result: Result<GroupDropdownResponse, NetworkError>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoadingGroups = false
            self.hasAttemptedInitialLoad = true
            
            switch result {
            case .success(let response):
                self.processSuccessfulGroupsResponse(response)
            case .failure(let error):
                //self.errorMessage = "Failed to load groups: \(error.localizedDescription)"
                self.errorMessage = "\(error.localizedDescription)"
            }
        }
    }
    
    private func processSuccessfulGroupsResponse(_ response: GroupDropdownResponse) {
        self.groups = response.groups
        self.cacheGroups(response.groups)
        
        if self.selectedGroupId.isEmpty, let firstGroup = self.groups.first {
            self.selectedGroupId = firstGroup.C_GroupsID
            UserDefaults.standard.set(firstGroup.C_GroupsID, forKey: "selectedClubGroupId")
            self.fetchActivityRecords()
        } else if !self.selectedGroupId.isEmpty {
            self.fetchActivityRecords()
        }
    }
    
    func fetchActivityRecords(forceRefresh: Bool = false) {
        guard !selectedGroupId.isEmpty else {
            errorMessage = "Please select a group."
            return
        }
        
        if !forceRefresh && isLoadingActivities { return }
        if !forceRefresh && isCacheValid() {
            loadCachedActivities(for: selectedGroupId)
        }
        
        isLoadingActivities = true
        errorMessage = nil
        
        performActivitiesRequest()
    }
    
    private func performActivitiesRequest() {
        UserDefaults.standard.set(selectedGroupId, forKey: "selectedClubGroupId")
        let parameters = ["groupid": selectedGroupId]
        
        NetworkService.shared.request(
            endpoint: "cas_add_record_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<ActivityResponse, NetworkError>) in
            self?.handleActivitiesResponse(result)
        }
    }
    
    private func handleActivitiesResponse(_ result: Result<ActivityResponse, NetworkError>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.isLoadingActivities = false
            
            switch result {
            case .success(let response):
                withAnimation {
                    self.activities = response.casRecord
                    self.cacheActivities(for: self.selectedGroupId, activities: response.casRecord)
                }
            case .failure(let error):
                // self.errorMessage = "Failed to load activities: \(error.localizedDescription)"
                self.errorMessage = "\(error.localizedDescription)"

            }
        }
    }
    
    func deleteRecord(record: ActivityRecord) {
        let parameters = ["recordid": record.C_ARecordID]
        errorMessage = nil
        HapticManager.shared.playFeedback(.medium)
        
        performDeleteRequest(parameters: parameters)
    }
    
    private func performDeleteRequest(parameters: [String: String]) {
        NetworkService.shared.request(
            endpoint: "cas_delete_record_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[String: String], NetworkError>) in
            self?.handleDeleteResponse(result, recordId: parameters["recordid"] ?? "")
        }
    }
    
    private func handleDeleteResponse(_ result: Result<[String: String], NetworkError>, recordId: String) {
        switch result {
        case .success(let response):
            processDeleteSuccess(response, recordId: recordId)
        case .failure(let error):
            //errorMessage = "Failed to delete record: \(error.localizedDescription)"
            errorMessage = "\(error.localizedDescription)"
        }
    }
    
    private func processDeleteSuccess(_ response: [String: String], recordId: String) {
        if response["status"] == "ok" {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.activities.removeAll { $0.C_ARecordID == recordId }
                self.cacheActivities(for: self.selectedGroupId, activities: self.activities)
                // Duplicate in ClubActivitiesView toast
                /*
                self.errorMessage = "Record deleted successfully"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        if self.errorMessage == "Record deleted successfully" {
                            self.errorMessage = nil
                        }
                    }
                }
                */
            }
        } else {
            self.errorMessage = response["status"] ?? "Unknown error"
        }
    }
    
    // MARK: - Copy Functions
    // showTemporaryMessage duplicate in ClubActivitiesView
    func copyTitle(_ activity: ActivityRecord) {
        HapticManager.shared.playFeedback(.light)
        UIPasteboard.general.string = activity.C_Theme
        //showTemporaryMessage("Title copied to clipboard!")
    }
    
    func copyReflection(_ activity: ActivityRecord) {
        HapticManager.shared.playFeedback(.light)
        UIPasteboard.general.string = activity.C_Reflection
        //showTemporaryMessage("Reflection copied to clipboard!")
    }
    
    func copyAll(_ activity: ActivityRecord) {
        HapticManager.shared.playFeedback(.light)
        let activityInfo = formatActivityInfo(activity)
        UIPasteboard.general.string = activityInfo
        //showTemporaryMessage("Activity copied to clipboard!")
    }
    
    private func formatActivityInfo(_ activity: ActivityRecord) -> String {
        """
        Theme: \(activity.C_Theme)
        Date: \(activity.C_Date)
        Duration: C: \(activity.C_DurationC), A: \(activity.C_DurationA), S: \(activity.C_DurationS)
        Reflection: \(activity.C_Reflection)
        """
    }
    
    private func showTemporaryMessage(_ message: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            errorMessage = message
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                if self?.errorMessage == message {
                    self?.errorMessage = nil
                }
            }
        }
    }
}
