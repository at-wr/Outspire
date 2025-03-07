import SwiftUI

struct AddRecordSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddRecordViewModel
    
    init(availableGroups: [ClubGroup], loggedInStudentId: String, onSave: @escaping () -> Void) {
        let model = AddRecordViewModel(
            availableGroups: availableGroups,
            loggedInStudentId: loggedInStudentId,
            onSave: onSave
        )
        _viewModel = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Group", selection: $viewModel.selectedGroupId) {
                    ForEach(viewModel.availableGroups) { group in
                        Text(group.C_NameE)
                            .tag(group.C_GroupsID)
                    }
                }
                
                DatePicker("Activity Date", selection: $viewModel.activityDate, displayedComponents: .date)
                
                TextField("Activity Title", text: $viewModel.activityTitle)
                
                Section(header: Text("Durations")) {
                    Stepper("C: \(viewModel.durationC) hours", value: $viewModel.durationC, in: 0...10, onEditingChanged: { _ in 
                        viewModel.validateDuration()
                    })
                    Stepper("A: \(viewModel.durationA) hours", value: $viewModel.durationA, in: 0...10, onEditingChanged: { _ in 
                        viewModel.validateDuration()
                    })
                    Stepper("S: \(viewModel.durationS) hours", value: $viewModel.durationS, in: 0...10, onEditingChanged: { _ in 
                        viewModel.validateDuration()
                    })
                }
                
                Section(header: Text("Reflection")) {
                    TextEditor(text: $viewModel.activityDescription)
                        .frame(minHeight: 100)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Add Record")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cacheFormData()  // Cache data when cancelling
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveRecord()
                        if viewModel.errorMessage == nil {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(true)  // Force user to use buttons
            .onDisappear {
                // This is a backup in case the form is dismissed in other ways
                viewModel.cacheFormData()
            }
        }
    }
}
