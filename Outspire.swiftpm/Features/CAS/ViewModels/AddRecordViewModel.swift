import SwiftUI

class AddRecordViewModel: ObservableObject {
    @Published var selectedGroupId: String = ""
    @Published var activityDate = Date()
    @Published var activityTitle: String = ""
    @Published var durationC: Int = 0
    @Published var durationA: Int = 0
    @Published var durationS: Int = 0
    @Published var activityDescription: String = ""
    @Published var errorMessage: String?
    
    let availableGroups: [ClubGroup] // Changed from Group to ClubGroup
    let loggedInStudentId: String
    let onSave: () -> Void
    
    private let sessionService = SessionService.shared
    
    var totalDuration: Int {
        durationC + durationA + durationS
    }
    
    init(availableGroups: [ClubGroup], loggedInStudentId: String, onSave: @escaping () -> Void) {
        self.availableGroups = availableGroups
        self.loggedInStudentId = loggedInStudentId
        self.onSave = onSave
        
        // Default first option
        if let firstGroup = availableGroups.first {
            self.selectedGroupId = firstGroup.C_GroupsID
        }
    }
    
    func validateDuration() {
        if totalDuration > 10 {
            errorMessage = "Total CAS duration cannot exceed 10 hours."
            durationC = 0
            durationA = 0
            durationS = 0
        } else {
            errorMessage = nil
        }
    }
    
    func saveRecord() {
        guard !selectedGroupId.isEmpty,
              !activityTitle.isEmpty,
              !activityDescription.isEmpty,
              activityDescription.count >= 80,
              totalDuration > 0 else {
            errorMessage = "Please fill all fields and ensure the description is at least 80 characters long, and CAS durations total at least 1 hour."
            return
        }
        
        guard let sessionId = sessionService.sessionId else {
            errorMessage = "No session ID available."
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let activityDateString = dateFormatter.string(from: activityDate)
        
        let parameters = [
            "groupid": selectedGroupId,
            "studentid": loggedInStudentId,
            "actdate": activityDateString,
            "acttitle": activityTitle,
            "durationC": String(durationC),
            "durationA": String(durationA),
            "durationS": String(durationS),
            "actdesc": activityDescription,
            "groupy": "0",
            "joiny": "0"
        ]
        
        NetworkService.shared.request(
            endpoint: "cas_save_record.php",
            parameters: parameters,
            sessionId: sessionId
        ) { [weak self] (result: Result<[String: String], NetworkError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response["status"] == "ok" {
                    self.onSave()
                } else {
                    self.errorMessage = response["status"]
                }
            case .failure(let error):
                self.errorMessage = "Unable to save record: \(error.localizedDescription)"
            }
        }
    }
}
