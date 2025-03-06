import SwiftUI

struct ClubActivitiesView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var viewModel = ClubActivitiesViewModel()
    @State private var showingAddRecordSheet = false
    
    var body: some View {
        VStack {
            Form {
                if viewModel.groups.isEmpty {
                    if viewModel.isLoadingGroups {
                        LoadingView(message: "Loading clubs...")
                    } else {
                        if sessionService.userInfo != nil {
                            Text("No clubs available.")
                                .foregroundStyle(.red)
                            Text("Try joining some to continue?")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Please sign in with TSIMS to continue...")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Picker("Select Group", selection: $viewModel.selectedGroupId) {
                        ForEach(viewModel.groups) { group in
                            Text(group.C_NameE).tag(group.C_GroupsID)
                        }
                    }
                    .onChange(of: viewModel.selectedGroupId) {
                        viewModel.fetchActivityRecords()
                    }
                    
                    if viewModel.isLoadingActivities {
                        LoadingView(message: "Loading activities...")
                    } else if viewModel.activities.isEmpty {
                        Text("No activity records available.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        List {
                            ForEach(viewModel.activities) { activity in
                                VStack(alignment: .leading) {
                                    Text("\(activity.C_Theme)")
                                        .fontWeight(.semibold)
                                    
                                    Text("Date: \(activity.C_Date)")
                                        .foregroundStyle(.secondary)
                                        .contentMargins(.top, 4)
                                    
                                    HStack {
                                        CASBadge(type: .creativity, value: activity.C_DurationC)
                                        CASBadge(type: .activity, value: activity.C_DurationA)
                                        CASBadge(type: .service, value: activity.C_DurationS)
                                    }
                                    
                                    Text("\(activity.C_Reflection)")
                                        .foregroundColor(.primary)
                                        .contentMargins(.top, 15)
                                }
                                .padding(.bottom, 10)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.recordToDelete = activity
                                        viewModel.showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        viewModel.copyActivityToClipboard(activity)
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(errorMessage.contains("copied") ? .green : .red)
                        .padding(.vertical)
                }
            }
            .navigationTitle("Club Activities")
            .contentMargins(.vertical, 10.0)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRecordSheet.toggle() }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingAddRecordSheet) {
                if let userId = sessionService.userInfo?.studentid {
                    AddRecordSheet(
                        availableGroups: viewModel.groups,
                        loggedInStudentId: userId,
                        onSave: { viewModel.fetchActivityRecords() }
                    )
                } else {
                    VStack(spacing: 10) {
                        Text(">_<")
                            .foregroundStyle(.primary)
                            .font(.title2)
                        Text("Maybe you haven't logged in yet?")
                            .foregroundStyle(.primary)
                        Text("Unable to retrieve user ID.")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .confirmationDialog(
                "Delete Record",
                isPresented: $viewModel.showingDeleteConfirmation,
                actions: {
                    Button("Delete", role: .destructive) {
                        if let record = viewModel.recordToDelete {
                            viewModel.deleteRecord(record: record)
                            viewModel.recordToDelete = nil
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: { Text("Are you sure you want to delete this record?") }
            )
            .onAppear {
                viewModel.fetchGroups()
            }
        }
    }
}