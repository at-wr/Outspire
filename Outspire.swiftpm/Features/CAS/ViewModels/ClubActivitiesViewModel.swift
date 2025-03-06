import SwiftUI

class ClubActivitiesViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var activities: [ActivityRecord] = []
    @Published var selectedGroupId: String = ""
    @Published var errorMessage: String?
    @Published var isLoadingGroups: Bool = false
    @Published var isLoadingActivities: Bool = false
    @Published var showingDeleteConfirmation = false
    @Published var recordToDelete: ActivityRecord?
    
    private let sessionService = SessionService.shared
    
    func fetchGroups() {
        isLoadingGroups = true
        errorMessage = nil
        
        NetworkService.shared.request<GroupDropdownResponse>(
            endpoint: "cas_add_mygroups_dropdown.php",
            sessionId: sessionService.sessionId
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingGroups = false
            
            switch result {
            case .success(let response):
                self.groups = response.groups
                
                if let firstGroup = self.groups.first {
                    self.selectedGroupId = firstGroup.C_GroupsID
                    self.fetchActivityRecords()
                }
            case .failure(let error):
                self.errorMessage = "Failed to load groups: \(error)"
            }
        }
    }
    
    func fetchActivityRecords() {
        guard !selectedGroupId.isEmpty else {
            errorMessage = "Please select a group."
            return
        }
        
        isLoadingActivities = true
        errorMessage = nil
        
        let parameters = ["groupid": selectedGroupId]
        
        NetworkService.shared.request<ActivityResponse>(
            endpoint: "cas_add_record_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingActivities = false
            
            switch result {
            case .success(let response):
                self.activities = response.casRecord
            case .failure(let error):
                self.errorMessage = "Failed to load activities: \(error)"
            }
        }
    }
    
    func deleteRecord(record: ActivityRecord) {
        let parameters = ["recordid": record.C_ARecordID]
        errorMessage = nil
        
        NetworkService.shared.request<[String: String]>(
            endpoint: "cas_delete_record_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response["status"] == "ok" {
                    withAnimation {
                        self.activities.removeAll { $0.C_ARecordID == record.C_ARecordID }
                    }
                } else {
                    self.errorMessage = response["status"] ?? "Unknown error"
                }
            case .failure(let error):
                self.errorMessage = "Failed to delete record: \(error)"
            }
        }
    }
    
    func copyActivityToClipboard(_ activity: ActivityRecord) {
        let activityInfo = """
        Theme: \(activity.C_Theme)
        Date: \(activity.C_Date)
        Duration: C: \(activity.C_DurationC), A: \(activity.C_DurationA), S: \(activity.C_DurationS)
        Reflection: \(activity.C_Reflection)
        """
        UIPasteboard.general.string = activityInfo
        errorMessage = "Activity copied to clipboard!"
    }
}