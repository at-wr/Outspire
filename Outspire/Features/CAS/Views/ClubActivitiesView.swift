import SwiftUI
import Toasts

struct ClubActivitiesView: View {
    @EnvironmentObject var sessionService: SessionService
    @StateObject private var viewModel = ClubActivitiesViewModel()
    @State private var showingAddRecordSheet = false
    @State private var animateList = false
    @State private var refreshButtonRotation = 0.0
    @EnvironmentObject var urlSchemeHandler: URLSchemeHandler
    @Environment(\.presentToast) var presentToast
    
    var body: some View {
        // Remove the nested NavigationView
        contentView
            .navigationTitle("Activity Records")
            .toolbarBackground(Color(UIColor.systemBackground))
            .contentMargins(.vertical, 10.0)
            .toolbar {
                ToolbarItem(id: "loadingIndicator", placement: .navigationBarTrailing) {
                    if viewModel.isLoadingActivities || viewModel.isLoadingGroups {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                
                ToolbarItem(id: "refreshButton", placement: .navigationBarTrailing) {
                    Button(action: handleRefreshAction) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(refreshButtonRotation))
                    }
                    .disabled(viewModel.isLoadingActivities || viewModel.isLoadingGroups)
                }
                
                ToolbarItem(id: "addButton", placement: .navigationBarTrailing) {
                    Button(action: { showingAddRecordSheet.toggle() }) {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(viewModel.isLoadingGroups || viewModel.isLoadingActivities || sessionService.userInfo == nil)
                }
            }
            .sheet(isPresented: $showingAddRecordSheet) { 
                addRecordSheet
                    .environmentObject(sessionService) // Explicitly pass environment object
            }
            .confirmationDialog(
                "Delete Record",
                isPresented: $viewModel.showingDeleteConfirmation,
                actions: { deleteConfirmationActions },
                message: { Text("Are you sure you want to delete this record?") }
            )
            .onAppear(perform: {
                handleOnAppear()
                
                // Handle URL scheme navigation to add an activity for a specific club
                if let activityClubId = urlSchemeHandler.navigateToAddActivity {
                    viewModel.setSelectedGroupById(activityClubId)
                    showingAddRecordSheet = true
                    
                    // Reset handler state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        urlSchemeHandler.navigateToAddActivity = nil
                    }
                }
            })
            .onChange(of: viewModel.isLoadingActivities) { _ in
                handleLoadingChange()
            }
            .onChange(of: viewModel.errorMessage) { errorMessage in
                if let errorMessage = errorMessage {
                    let icon = errorMessage.contains("copied") ? 
                    "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    let toast = ToastValue(
                        icon: Image(systemName: icon).foregroundStyle(.red),
                        message: errorMessage
                    )
                    presentToast(toast)
                }
            }
            .onChange(of: urlSchemeHandler.closeAllSheets) { newValue in
                if newValue {
                    // Close the add record sheet if it's open
                    showingAddRecordSheet = false
                    
                    // Reset any other dialog states if needed
                    viewModel.showingDeleteConfirmation = false
                }
            }
    }
    
    private var contentView: some View {
        Form {
            GroupSelectorSection(viewModel: viewModel)
            ActivitiesSection(
                viewModel: viewModel,
                sessionService: sessionService,
                showingAddRecordSheet: $showingAddRecordSheet,
                animateList: animateList
            )
            // 删除 ToastSection，改为使用 presentToast
        }
        .scrollContentBackground(.visible)
        .animation(.spring(response: 0.4), value: viewModel.isLoadingActivities)
        .animation(.spring(response: 0.4), value: viewModel.activities.isEmpty)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.errorMessage)
        .refreshable(action: handleRefresh) // Fixed refreshable syntax
    }
    
    @ViewBuilder
    private var addRecordSheet: some View {
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
    
    private var deleteConfirmationActions: some View {
        Group {
            Button("Delete", role: .destructive) {
                if let record = viewModel.recordToDelete {
                    viewModel.deleteRecord(record: record)
                    
                    let toast = ToastValue(
                        icon: Image(systemName: "trash.fill").foregroundStyle(.red),
                        message: "Record Deleted"
                    )
                    presentToast(toast)
                    
                    viewModel.recordToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func handleOnAppear() {
        if viewModel.groups.isEmpty {
            viewModel.fetchGroups()
        } else if !viewModel.isCacheValid() {
            viewModel.fetchActivityRecords(forceRefresh: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateList = true
            }
        }
    }
    
    private func handleLoadingChange() {
        if !viewModel.isLoadingActivities {
            animateList = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateList = true
                }
            }
        }
    }
    
    private func handleRefreshAction() {
        withAnimation {
            refreshButtonRotation += 360
        }
        if viewModel.isLoadingActivities { return }
        
        if viewModel.groups.isEmpty {
            viewModel.fetchGroups(forceRefresh: true)
        } else {
            viewModel.fetchActivityRecords(forceRefresh: true)
        }
    }
    
    @Sendable private func handleRefresh() async {  // Added @Sendable to fix data race warning
        HapticManager.shared.playFeedback(.medium)
        if viewModel.groups.isEmpty {
            await viewModel.fetchGroupsAsync(forceRefresh: true)
        } else {
            await viewModel.fetchActivityRecordsAsync(forceRefresh: true)
        }
    }
}

struct GroupSelectorSection: View {
    @ObservedObject var viewModel: ClubActivitiesViewModel
    
    var body: some View {
        Section {
            if !viewModel.groups.isEmpty {
                Picker("Club", selection: $viewModel.selectedGroupId) {
                    ForEach(viewModel.groups) { group in
                        Text(group.C_NameE).tag(group.C_GroupsID)
                    }
                }
                .onChange(of: viewModel.selectedGroupId) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.fetchActivityRecords()
                    }
                }
                .disabled(viewModel.isLoadingActivities)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: viewModel.groups.isEmpty)
            }
        }
    }
}

struct ActivitiesSection: View {
    @ObservedObject var viewModel: ClubActivitiesViewModel
    let sessionService: SessionService
    @Binding var showingAddRecordSheet: Bool
    let animateList: Bool
    @State private var hasCompletedInitialLoad = false
    @Environment(\.presentToast) var presentToast
    
    var body: some View {
        Section {
            if viewModel.groups.isEmpty && !viewModel.isLoadingGroups {
                Group {
                    if sessionService.userInfo != nil {
                        ErrorView(
                            errorMessage: "No clubs available. Try joining some to continue?",
                            retryAction: { 
                                viewModel.fetchGroups(forceRefresh: true)
                                
                                let toast = ToastValue(
                                    icon: Image(systemName: "arrow.clockwise"),
                                    message: "Refreshing clubs..."
                                )
                                presentToast(toast)
                            }
                        )
                    } else {
                        ErrorView(errorMessage: "Please sign in with TSIMS to continue...")
                    }
                }
                .transition(.scale.combined(with: .opacity))
            } else if viewModel.isLoadingActivities || !hasCompletedInitialLoad {
                // Show skeleton during loading or before completing initial load
                ActivitySkeletonView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isLoadingActivities)
            } else if viewModel.activities.isEmpty {
                // Only show empty state after loading is complete and we confirmed no activities
                ClubEmptyStateView(action: { showingAddRecordSheet.toggle() })
                    .transition(.scale.combined(with: .opacity))
            } else {
                ActivitiesList(viewModel: viewModel, animateList: animateList)
                    .transition(.opacity)
                    .blur(radius: viewModel.isLoadingActivities ? 1.0 : 0)
                    .opacity(viewModel.isLoadingActivities ? 0.7 : 1.0)
            }
        }
        .onChange(of: viewModel.isLoadingActivities) { isLoading in
            // After loading completes, mark initial load as complete
            if !isLoading && !hasCompletedInitialLoad {
                hasCompletedInitialLoad = true
            }
        }
    }
}

struct CALoadingIndicator: View {
    let isLoadingActivities: Bool
    let isLoadingGroups: Bool
    
    var body: some View {
        if isLoadingActivities || isLoadingGroups {
            ProgressView()
                .controlSize(.small)
                .transition(.opacity.combined(with: .scale))
        }
    }
}

// now moved to SchoolArrangement/Views/Components/UIComponents
// need to use :3
struct CARefreshButton: View {
    let isLoadingActivities: Bool
    let isLoadingGroups: Bool
    let groupsEmpty: Bool
    @Binding var rotation: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise")
                .rotationEffect(.degrees(rotation))
                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: rotation)
        }
        .disabled(isLoadingActivities || isLoadingGroups)
    }
}

struct AddButton: View {
    let isLoadingGroups: Bool
    let isLoadingActivities: Bool
    let userInfo: UserInfo?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
        }
        .disabled(isLoadingGroups || isLoadingActivities || userInfo == nil)
    }
}

struct ClubEmptyStateView: View {
    let action: () -> Void
    
    var body: some View {
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
            Button(action: action) {
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
}

struct ActivitiesList: View {
    @ObservedObject var viewModel: ClubActivitiesViewModel
    let animateList: Bool
    
    var body: some View {
        ForEach(Array(viewModel.activities.enumerated()), id: \.element.id) { index, activity in
            ActivityCardView(activity: activity, viewModel: viewModel)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .offset(x: animateList ? 0 : 100)
                .opacity(animateList ? 1 : 0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.7)
                    .delay(Double(index) * 0.05),
                    value: animateList
                )
                .contentTransition(.opacity)
        }
    }
}

struct ActivityCardView: View {
    let activity: ActivityRecord
    @ObservedObject var viewModel: ClubActivitiesViewModel
    @Environment(\.presentToast) var presentToast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.C_Theme)
                    .font(.headline)
                    .lineLimit(1)
                Text("Date: \(formatDate(activity.C_Date))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                CASBadge(type: .creativity, value: activity.C_DurationC)
                    .transition(.scale)
                CASBadge(type: .activity, value: activity.C_DurationA)
                    .transition(.scale)
                CASBadge(type: .service, value: activity.C_DurationS)
                    .transition(.scale)
                Spacer()
                Text("Total: \(String(format: "%.1f", totalDuration))h")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
            ReflectionView(text: activity.C_Reflection)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .contextMenu {
            Button(action: {
                viewModel.recordToDelete = activity
                viewModel.showingDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
            Menu {
                Button(action: { 
                    viewModel.copyTitle(activity)
                    let toast = ToastValue(
                        icon: Image(systemName: "doc.on.clipboard"),
                        message: "Title Copied to Clipboard"
                    )
                    presentToast(toast)
                }) {
                    Label("Copy Title", systemImage: "textformat")
                }
                Button(action: { 
                    viewModel.copyReflection(activity)
                    let toast = ToastValue(
                        icon: Image(systemName: "doc.on.clipboard"),
                        message: "Reflection Copied to Clipboard"
                    )
                    presentToast(toast)
                }) {
                    Label("Copy Reflection", systemImage: "doc.text")
                }
                Button(action: { 
                    viewModel.copyAll(activity)
                    let toast = ToastValue(
                        icon: Image(systemName: "doc.on.clipboard"),
                        message: "Activity Copied to Clipboard"
                    )
                    presentToast(toast)
                }) {
                    Label("Copy All", systemImage: "doc.on.doc")
                }
            } label: {
                Label("Copy", systemImage: "doc.on.clipboard")
            }
        }
        // Removed swipeActions as requested
    }
    
    private var totalDuration: Double {
        (Double(activity.C_DurationC) ?? 0) +
        (Double(activity.C_DurationA) ?? 0) +
        (Double(activity.C_DurationS) ?? 0)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if inputFormatter.date(from: dateString) == nil {
            inputFormatter.dateFormat = "yyyy-MM-dd"
        }
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .none
            return outputFormatter.string(from: date)
        }
        
        return dateString.contains(" ") ? String(dateString.split(separator: " ")[0]) : dateString
    }
}

struct ReflectionView: View {
    let text: String
    @State private var isExpanded = false
    @State private var buttonScale = 1.0
    
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
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeOut(duration: 0.3), value: isExpanded)
            if text.count > 100 {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
                    }
                    .padding(.top, 4)
                    .scaleEffect(buttonScale)
                }
                .buttonStyle(.plain)
                .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { isPressing in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        buttonScale = isPressing ? 0.92 : 1.0
                    }
                }, perform: {})
            }
        }
    }
}

class HapticManager {
    static let shared = HapticManager()
    
    func playFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
