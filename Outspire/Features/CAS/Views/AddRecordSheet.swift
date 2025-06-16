import Foundation
import SwiftUI
import Toasts

struct AddRecordSheet: View {
    @Environment(\.presentToast) var presentToast
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddRecordViewModel

    let clubActivitiesViewModel: ClubActivitiesViewModel

    init(
        availableGroups: [ClubGroup],
        loggedInStudentId: String,
        onSave: @escaping () -> Void,
        clubActivitiesViewModel: ClubActivitiesViewModel
    ) {
        self.clubActivitiesViewModel = clubActivitiesViewModel
        let model = AddRecordViewModel(
            availableGroups: availableGroups,
            loggedInStudentId: loggedInStudentId,
            onSave: onSave,
            clubActivitiesViewModel: clubActivitiesViewModel
        )
        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            Form {
                Picker("Club", selection: $viewModel.selectedGroupId) {
                    ForEach(viewModel.availableGroups) { group in
                        Text(group.C_NameE)
                            .tag(group.C_GroupsID)
                    }
                }

                DatePicker("Date", selection: $viewModel.activityDate, displayedComponents: .date)

                TextField("Title...", text: $viewModel.activityTitle)

                Section(header: Text("Durations")) {
                    Stepper(
                        "C: \(viewModel.durationC) hours", value: $viewModel.durationC, in: 0...10,
                        onEditingChanged: { _ in
                            HapticManager.shared.playStepperChange()
                            viewModel.validateDuration()
                            if let errorMessage = viewModel.errorMessage {
                                HapticManager.shared.playError()
                                let toast = ToastValue(
                                    icon: Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.red),
                                    message: errorMessage
                                )
                                presentToast(toast)
                            }
                        })
                    Stepper(
                        "A: \(viewModel.durationA) hours", value: $viewModel.durationA, in: 0...10,
                        onEditingChanged: { _ in
                            HapticManager.shared.playStepperChange()
                            viewModel.validateDuration()
                            if let errorMessage = viewModel.errorMessage {
                                HapticManager.shared.playError()
                                let toast = ToastValue(
                                    icon: Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.red),
                                    message: errorMessage
                                )
                                presentToast(toast)
                            }
                        })
                    Stepper(
                        "S: \(viewModel.durationS) hours", value: $viewModel.durationS, in: 0...10,
                        onEditingChanged: { _ in
                            HapticManager.shared.playStepperChange()
                            viewModel.validateDuration()
                            if let errorMessage = viewModel.errorMessage {
                                HapticManager.shared.playError()
                                let toast = ToastValue(
                                    icon: Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.red),
                                    message: errorMessage
                                )
                                presentToast(toast)
                            }
                        })
                }

                Section(
                    header:
                        HStack {
                            Text("Reflection")
                            Spacer()
                            Text("\(viewModel.descriptionWordCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                ) {
                    TextEditor(text: $viewModel.activityDescription)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if viewModel.activityDescription == "" {
                                Text(
                                    "Here goes your reflection of at least 80 characters...\nAutosave enabled, no worries!"
                                )
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                                .padding(.top, 8)
                                .padding(.leading, 3)
                            }
                        }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("New Record")
            .toolbarBackground(Color(UIColor.systemBackground))
            .toolbar {
                ToolbarItem(id: "cancelButton", placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.playButtonTap()
                        viewModel.cacheFormData()  // Cache data when cancelling
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(id: "llmSuggest", placement: .primaryAction) {
                    Menu {
                        Button {
                            HapticManager.shared.playButtonTap()
                            viewModel.fetchLLMSuggestion()
                        } label: {
                            Label("Suggest", systemImage: "pencil.and.scribble")
                        }
                        Button {
                            HapticManager.shared.playButtonTap()
                            viewModel.revertSuggestion()
                        } label: {
                            Label("Revert", systemImage: "arrow.uturn.backward")
                        }
                        .disabled(!viewModel.canRevertSuggestion)
                        Button(role: .destructive) {
                            HapticManager.shared.playDelete()
                            viewModel.clearForm()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                        // Future: add more options like "Polish", "Extend"
                    } label: {
                        if viewModel.isFetchingSuggestion {
                            ProgressView()
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                    }
                    .disabled(viewModel.isFetchingSuggestion)
                }

                // Un-comment this after Xcode 26
                //                if #available(iOS 26.0, *) {
                //                    ToolbarSpacer(.fixed, placement: .primaryAction)
                //                }

                ToolbarItem(id: "saveButton", placement: .primaryAction) {
                    Button("Save") {
                        HapticManager.shared.playFormSubmission()
                        viewModel.saveRecord()
                        if let errorMessage = viewModel.errorMessage {
                            HapticManager.shared.playError()
                            let toast = ToastValue(
                                icon: Image(systemName: "exclamationmark.triangle").foregroundStyle(
                                    .red),
                                message: errorMessage
                            )
                            presentToast(toast)
                        } else {
                            HapticManager.shared.playSuccessfulSave()
                            let toast = ToastValue(
                                icon: Image(systemName: "checkmark.circle").foregroundStyle(.green),
                                message: "Record saved successfully"
                            )
                            presentToast(toast)
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
            .alert(
                isPresented: Binding<Bool>(
                    get: { viewModel.suggestionError != nil },
                    set: { if !$0 { viewModel.suggestionError = nil } }
                )
            ) {
                Alert(
                    title: Text("Suggestion Error"),
                    message: Text(viewModel.suggestionError ?? ""),
                    dismissButton: .default(Text("OK")) {
                        HapticManager.shared.playButtonTap()
                        viewModel.suggestionError = nil
                    }
                )
            }
            .alert(
                "DISCLAIMER",
                isPresented: $viewModel.showFirstTimeSuggestionAlert
            ) {
                Button("Agree & Proceed", role: .cancel) {
                    HapticManager.shared.playButtonTap()
                    viewModel.dismissFirstTimeSuggestionAlert()
                }
            } message: {
                Text(DisclaimerManager.fullDisclaimerText)
            }
            .alert(
                "Suggestion Completed",
                isPresented: $viewModel.showCompletedSuggestionAlert
            ) {
                Button("Agree", role: .cancel) {
                    HapticManager.shared.playSuccessFeedback()
                    viewModel.dismissCompletedSuggestionAlert()
                }
            } message: {
                Text(DisclaimerManager.shortDisclaimerText)
            }
        }
    }
}
