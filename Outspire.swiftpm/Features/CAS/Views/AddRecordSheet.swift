import SwiftUI

struct AddRecordSheet: View {
    @Environment(\.presentationMode) var presentationMode
    var availableGroups: [Group]
    var loggedInStudentId: String
    var onSave: () -> Void
    
    @State private var selectedGroupId: String = ""
    @State private var activityDate = Date()
    @State private var activityTitle: String = ""
    @State private var durationC: Int = 0
    @State private var durationA: Int = 0
    @State private var durationS: Int = 0
    @State private var activityDescription: String = ""
    @State private var errorMessage: String?
    
    var totalDuration: Int {
        durationC + durationA + durationS
    }
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Group", selection: $selectedGroupId) {
                    ForEach(availableGroups) { group in
                        Text(group.C_NameE)
                            .tag(group.C_GroupsID)
                    }
                }
                .onAppear {
                    // Default first option
                    if let firstGroup = availableGroups.first {
                        selectedGroupId = firstGroup.C_GroupsID
                    }
                }
                
                DatePicker("Activity Date", selection: $activityDate, displayedComponents: .date)
                
                TextField("Activity Title", text: $activityTitle)
                
                Section(header: Text("Durations")) {
                    Stepper("C: \(durationC) hours", value: $durationC, in: 0...10) {_ in 
                        validateDuration()
                    }
                    Stepper("A: \(durationA) hours", value: $durationA, in: 0...10) {_ in 
                        validateDuration()
                    }
                    Stepper("S: \(durationS) hours", value: $durationS, in: 0...10) {_ in 
                        validateDuration()
                    }
                }
                
                Section(header: Text("Reflection")) {
                    TextEditor(text: $activityDescription)
                        .frame(minHeight: 100)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Add Record")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecord()
                    }
                }
            }
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
        
        errorMessage = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let parameters = [
            "groupid": selectedGroupId,
            "studentid": loggedInStudentId,
            "actdate": dateFormatter.string(from: activityDate),
            "acttitle": activityTitle,
            "durationC": String(durationC),
            "durationA": String(durationA),
            "durationS": String(durationS),
            "actdesc": activityDescription,
            "groupy": "0",
            "joiny": "0"
        ]
        
        NetworkService.shared.request<[String: String]>(
            endpoint: "cas_save_record.php",
            parameters: parameters,
            sessionId: SessionService.shared.sessionId
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response["status"] == "ok" {
                    presentationMode.wrappedValue.dismiss()
                    onSave()
                } else {
                    self.errorMessage = response["status"]
                }
            case .failure(let error):
                self.errorMessage = "Unable to save record: \(error)"
            }
        }
    }
}
