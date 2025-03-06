import SwiftUI

struct ClubActivitiesView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var viewModel = ClubActivitiesViewModel()
    @State private var showingAddRecordSheet = false
    
    var body: some View {
        contentView
            .navigationTitle("Club Activities")
            .contentMargins(.vertical, 10.0)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoadingActivities || viewModel.isLoadingGroups {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if viewModel.isLoadingActivities {
                            // Don't allow multiple refresh requests
                            return
                        }
                        
                        if viewModel.groups.isEmpty {
                            viewModel.fetchGroups(forceRefresh: true)
                        } else {
                            viewModel.fetchActivityRecords(forceRefresh: true)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingActivities || viewModel.isLoadingGroups)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRecordSheet.toggle() }) {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(viewModel.isLoadingGroups)
                }
            }
            .sheet(isPresented: $showingAddRecordSheet) {
                if let userId = sessionService.userInfo?.studentid {
                    AddRecordSheet(
                        availableGroups: viewModel.groups,
                        loggedInStudentId: userId,
                        onSave: { viewModel.fetchActivityRecords(forceRefresh: true) }
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
                // On appear, check if we need to refresh data
                if viewModel.groups.isEmpty {
                    viewModel.fetchGroups()
                } else if !viewModel.isCacheValid() {
                    // Cache expired, refresh data
                    viewModel.fetchActivityRecords(forceRefresh: true)
                }
            }
    }
    
    // Main content based on the state
    private var contentView: some View {
        Form {
            // Group Selector Section
            Section {
                if !viewModel.groups.isEmpty {
                    Picker("Select Group", selection: $viewModel.selectedGroupId) {
                        ForEach(viewModel.groups) { group in
                            Text(group.C_NameE).tag(group.C_GroupsID)
                        }
                    }
                    .onChange(of: viewModel.selectedGroupId) {
                        viewModel.fetchActivityRecords()
                    }
                    .disabled(viewModel.isLoadingActivities)
                }
            }
            
            // Activities Section
            Section {
                if viewModel.groups.isEmpty && !viewModel.isLoadingGroups {
                    if sessionService.userInfo != nil {
                        ErrorView(
                            errorMessage: "No clubs available. Try joining some to continue?",
                            retryAction: { viewModel.fetchGroups(forceRefresh: true) }
                        )
                    } else {
                        ErrorView(
                            errorMessage: "Please sign in with TSIMS to continue..."
                        )
                    }
                } else if viewModel.isLoadingActivities && viewModel.activities.isEmpty {
                    // Only show skeleton when we don't have any data yet
                    ActivitySkeletonView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .transition(.opacity)
                } else if viewModel.activities.isEmpty {
                    Text("No activity records available.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .transition(.opacity)
                } else {
                    activitiesList
                        .transition(.opacity)
                        .opacity(viewModel.isLoadingActivities ? 0.6 : 1.0) // Dim while refreshing
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(errorMessage.contains("copied") ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoadingActivities)
        .animation(.easeInOut(duration: 0.3), value: viewModel.activities.isEmpty)
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .refreshable {
            // Pull to refresh
            if viewModel.groups.isEmpty {
                viewModel.fetchGroups(forceRefresh: true)
            } else {
                viewModel.fetchActivityRecords(forceRefresh: true)
            }
        }
    }
    
    // Extract activities list to a separate view for better organization
    private var activitiesList: some View {
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
            .padding(.vertical, 10)
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