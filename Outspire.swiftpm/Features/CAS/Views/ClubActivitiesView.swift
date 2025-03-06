import SwiftUI

struct ClubActivitiesView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var viewModel = ClubActivitiesViewModel()
    @State private var showingAddRecordSheet = false
    @State private var animateList = false
    @State private var refreshButtonRotation = 0.0
    
    var body: some View {
        contentView
            .navigationTitle("Club Activities")
            .contentMargins(.vertical, 10.0)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoadingActivities || viewModel.isLoadingGroups {
                        ProgressView()
                            .controlSize(.small)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            refreshButtonRotation += 360
                        }
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
                            .rotationEffect(.degrees(refreshButtonRotation))
                            .animation(.spring(response: 0.6, dampingFraction: 0.5), value: refreshButtonRotation)
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
                    .presentationDetents([.medium, .large])
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
                
                // Trigger animations after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateList = true
                    }
                }
            }
            .onChange(of: viewModel.isLoadingActivities) { isLoading in
                if !isLoading {
                    // Reset and retrigger staggered animations when loading completes
                    animateList = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            animateList = true
                        }
                    }
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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.fetchActivityRecords()
                        }
                    }
                    .disabled(viewModel.isLoadingActivities)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.groups.isEmpty)
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
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        ErrorView(
                            errorMessage: "Please sign in with TSIMS to continue..."
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                } else if viewModel.isLoadingActivities && viewModel.activities.isEmpty {
                    // Only show skeleton when we don't have any data yet
                    ActivitySkeletonView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.isLoadingActivities)
                } else if viewModel.activities.isEmpty {
                    emptyStateView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    activitiesList
                        .transition(.opacity)
                        // Apply subtle blur when refreshing instead of just dimming
                        .blur(radius: viewModel.isLoadingActivities ? 1.0 : 0)
                        .opacity(viewModel.isLoadingActivities ? 0.7 : 1.0)
                }
            }
            
            // Toast Messages
            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: errorMessage.contains("copied") ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(errorMessage.contains("copied") ? .green : .red)
                        
                        Text(errorMessage)
                            .foregroundColor(errorMessage.contains("copied") ? .green : .red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .contentTransition(.opacity)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(errorMessage.contains("copied") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .padding(.vertical, 2)
                )
            }
        }
        .scrollContentBackground(.visible)
        .animation(.spring(response: 0.4), value: viewModel.isLoadingActivities)
        .animation(.spring(response: 0.4), value: viewModel.activities.isEmpty)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.errorMessage)
        .refreshable {
            // Pull to refresh with haptic feedback
            HapticManager.shared.playFeedback(.medium)
            
            if viewModel.groups.isEmpty {
                await viewModel.fetchGroupsAsync(forceRefresh: true)
            } else {
                await viewModel.fetchActivityRecordsAsync(forceRefresh: true)
            }
        }
    }
    
    // Empty state view with nicer design
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
                .padding(.bottom, 8)
                
            Text("No activity records available")
                .font(.headline)
                .foregroundStyle(.secondary)
                
            Text("Add a new activity using the + button")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                
            Button(action: { showingAddRecordSheet.toggle() }) {
                Label("Add New Activity", systemImage: "plus.circle")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // Extract activities list to a separate view with enhanced styling
    private var activitiesList: some View {
        ForEach(Array(viewModel.activities.enumerated()), id: \.element.id) { index, activity in
            ActivityCardView(activity: activity, viewModel: viewModel)
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                .listRowBackground(Color.clear)
                .offset(x: animateList ? 0 : 100, y: 0)
                .opacity(animateList ? 1 : 0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.7)
                    .delay(Double(index) * 0.05), // Staggered animation
                    value: animateList
                )
                .contentTransition(.opacity)
        }
    }
}

// Extract activity card to a separate component for better organization
struct ActivityCardView: View {
    let activity: ActivityRecord
    let viewModel: ClubActivitiesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and date in header
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.C_Theme)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Date: \(formatDate(activity.C_Date))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // CAS badges with improved layout
            HStack(spacing: 8) {
                CASBadge(type: .creativity, value: activity.C_DurationC)
                    .transition(.scale)
                CASBadge(type: .activity, value: activity.C_DurationA)
                    .transition(.scale)
                CASBadge(type: .service, value: activity.C_DurationS)
                    .transition(.scale)
                
                Spacer()
                
                // Total duration
                let totalDuration = (Double(activity.C_DurationC) ?? 0) + 
                                   (Double(activity.C_DurationA) ?? 0) + 
                                   (Double(activity.C_DurationS) ?? 0)
                
                Text("Total: \(String(format: "%.1f", totalDuration))h")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Reflection with expanding/collapsing text
            ReflectionView(text: activity.C_Reflection)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .contextMenu {
            Button(action: {
                viewModel.recordToDelete = activity
                viewModel.showingDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: {
                viewModel.copyActivityToClipboard(activity)
            }) {
                Label("Copy to Clipboard", systemImage: "doc.on.doc")
            }
        }
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
            .tint(.blue)
        }
    }
    
    // Format date to be more user-friendly
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

// Expandable reflection view
struct ReflectionView: View {
    let text: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reflection")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text(text)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .foregroundStyle(.primary)
            
            if text.count > 100 {
                Button(action: { isExpanded.toggle() }) {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.top, 4)
                }
            }
        }
    }
}

// Haptic feedback manager
class HapticManager {
    static let shared = HapticManager()
    
    func playFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}