import SwiftUI
import Toasts

struct ClubInfoView: View {
    @StateObject private var viewModel = ClubInfoViewModel()
    @EnvironmentObject var sessionService: SessionService
    @Environment(\.presentToast) var presentToast
    @State private var animateList = false
    @State private var refreshButtonRotation = 0.0
    @State private var showingJoinOptions = false
    @State private var showingExitConfirmation = false
    @State private var preservedGroupId: String? = nil
    @State private var initialMembershipCheckComplete = false
    @EnvironmentObject var urlSchemeHandler: URLSchemeHandler
    
    var body: some View {
        VStack {
            Form {
                selectionSection
                
                emptyStateSection
                
                errorMessageView
                
                if viewModel.isLoading && (viewModel.groupInfo == nil || !viewModel.refreshing) {
                    loadingSection
                } else if let groupInfo = viewModel.groupInfo {
                    clubInfoSection(groupInfo: groupInfo)
                    memberSection
                }
            }
            .contentMargins(.vertical, 10.0)
            .textSelection(.enabled)
            .navigationBarTitle("Clubs")
            .toolbarBackground(Color(UIColor.systemBackground))
            .toolbar {
                // Replace individual toolbar content with inline implementation
                ToolbarItem(id: "progressView", placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                
                ToolbarItem(id: "clubAction", placement: .navigationBarTrailing) {
                    if sessionService.isAuthenticated, 
                       !viewModel.isLoading, 
                       viewModel.selectedGroup != nil {
                        #if targetEnvironment(macCatalyst)
                        // Use a menu approach for Mac Catalyst
                        Menu {
                            if viewModel.isUserMember {
                                Button(role: .destructive, action: {
                                    showingExitConfirmation = true
                                }) {
                                    Label("Exit Club", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            } else {
                                Button(action: {
                                    viewModel.joinClub(asProject: false)
                                }) {
                                    Label("Join Club", systemImage: "person.badge.plus")
                                }
                                
                                Button(action: {
                                    viewModel.joinClub(asProject: true)
                                }) {
                                    Label("Join as Project", systemImage: "star.circle")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: viewModel.isUserMember ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.badge.plus")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(viewModel.isUserMember ? .green : .cyan)
                                if viewModel.isJoiningClub || viewModel.isExitingClub {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .scaleEffect(0.7)
                                }
                            }
                        }
                        .disabled(viewModel.isJoiningClub || viewModel.isExitingClub)
                        .onChange(of: viewModel.isUserMember) { _, newValue in
                            if initialMembershipCheckComplete {
                                if newValue {
                                    presentSuccessToast(message: "Successfully joined club")
                                } else {
                                    presentSuccessToast(message: "Successfully exited club")
                                }
                            } else {
                                initialMembershipCheckComplete = true
                            }
                        }
                        .help(viewModel.isUserMember ? "Exit Club" : "Join Club")
                        #else
                        Menu {
                            if viewModel.isUserMember {
                                Button(role: .destructive, action: {
                                    showingExitConfirmation = true
                                }) {
                                    Label("Exit Club", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            } else {
                                Button(action: {
                                    viewModel.joinClub(asProject: false)
                                }) {
                                    Label("Join Club", systemImage: "person.badge.plus")
                                }
                                
                                Button(action: {
                                    viewModel.joinClub(asProject: true)
                                }) {
                                    Label("Join as Project", systemImage: "star.circle")
                                }
                            }
                        } label: {
                            Image(systemName: viewModel.isUserMember ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.badge.plus")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(viewModel.isUserMember ? .green : .cyan)
                                .opacity(viewModel.isJoiningClub || viewModel.isExitingClub ? 0.5 : 1.0)
                                .overlay {
                                    if viewModel.isJoiningClub || viewModel.isExitingClub {
                                        ProgressView()
                                            .controlSize(.mini)
                                    }
                                }
                        }
                        .disabled(viewModel.isJoiningClub || viewModel.isExitingClub)
                        .onChange(of: viewModel.isUserMember) { _, newValue in
                            if initialMembershipCheckComplete {
                                if newValue {
                                    presentSuccessToast(message: "Successfully joined club")
                                } else {
                                    presentSuccessToast(message: "Successfully exited club")
                                }
                            } else {
                                initialMembershipCheckComplete = true
                            }
                        }
                        #endif
                    }
                }
                
                // Share button
                ToolbarItem(id: "shareButton", placement: .navigationBarTrailing) {
                    if let groupInfo = viewModel.groupInfo {
                        Button(action: {
                            shareClub(groupInfo: groupInfo)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                
                ToolbarItem(id: "refreshButton", placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            refreshButtonRotation += 360
                        }
                        
                        // Store current selection
                        let currentGroupId = viewModel.selectedGroup?.C_GroupsID
                        
                        if viewModel.selectedCategory != nil {
                            viewModel.fetchGroups(for: viewModel.selectedCategory!)
                        } else {
                            viewModel.fetchCategories()
                        }
                        
                        if viewModel.selectedGroup != nil {
                            viewModel.fetchGroupInfo(for: viewModel.selectedGroup!)
                        }
                        
                        // Preserve club ID for restoration
                        if let id = currentGroupId {
                            preservedGroupId = id
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(refreshButtonRotation))
                            .animation(.spring(response: 0.6, dampingFraction: 0.5), value: refreshButtonRotation)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onAppear {
                onAppearSetup()
                
                // Handle URL scheme navigation
                if let clubId = urlSchemeHandler.navigateToClub {
                    print("ClubInfoView detected navigateToClub: \(clubId)")
                    
                    // Use our enhanced direct navigation method
                    viewModel.navigateToClubById(clubId)
                    
                    // Save the ID for potential restoration
                    preservedGroupId = clubId
                    
                    // Reset the handler state with a slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        urlSchemeHandler.navigateToClub = nil
                    }
                }
            }
            // Add this onChange handler to respond to URL navigation even when the view is already visible
            .onChange(of: urlSchemeHandler.navigateToClub) { _, newClubId in
                if let clubId = newClubId {
                    print("ClubInfoView detected navigateToClub change: \(clubId)")
                    
                    // Reset state to force a fresh navigation
                    viewModel.pendingClubId = nil
                    viewModel.isFromURLNavigation = false
                    
                    // Use our enhanced direct navigation method
                    viewModel.navigateToClubById(clubId)
                    
                    // Save the ID for potential restoration
                    preservedGroupId = clubId
                    
                    // Reset the handler state with a slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        urlSchemeHandler.navigateToClub = nil
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { oldValue, newValue in
                handleLoadingChange(newValue)
            } // use this to fix the stupid iOS 17 deprecation warning
            .animation(.spring(response: 0.4), value: viewModel.isLoading)
            .onChange(of: viewModel.selectedCategory) { _, _ in
                // Store current group ID when category changes
                if let currentGroup = viewModel.selectedGroup {
                    preservedGroupId = currentGroup.C_GroupsID
                }
            }
            .onChange(of: viewModel.groups) { _, newGroups in
                // Try to restore the previously selected group when groups list changes
                if let id = preservedGroupId, 
                   let previousGroup = newGroups.first(where: { $0.C_GroupsID == id }) {
                    viewModel.selectedGroup = previousGroup
                }
            }
            .onChange(of: urlSchemeHandler.closeAllSheets) { newValue in
                if newValue {
                    // Close any active sheets
                    showingJoinOptions = false
                    showingExitConfirmation = false
                }
            }
            .confirmationDialog(
                "Exit Club",
                isPresented: $showingExitConfirmation,
                actions: {
                    Button("Exit Club", role: .destructive) {
                        viewModel.exitClub()
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: {
                    Text("Are you sure you want to exit this club?")
                }
            )
        }
        .refreshable {
            handleRefresh()
        }
    }
    
    // MARK: - Toolbar Items
    
    private var clubActionButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if sessionService.isAuthenticated, 
               !viewModel.isLoading, 
               viewModel.selectedGroup != nil {
                #if targetEnvironment(macCatalyst)
                // Use a more compatible approach for Mac Catalyst
                Button(action: {
                    if viewModel.isUserMember {
                        showingExitConfirmation = true
                    } else {
                        viewModel.joinClub(asProject: false)
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.isUserMember ? "person.fill.checkmark" : "person.crop.circle.badge.plus")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(viewModel.isUserMember ? .green : .blue)
                        if viewModel.isJoiningClub || viewModel.isExitingClub {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.7)
                        }
                    }
                }
                .disabled(viewModel.isJoiningClub || viewModel.isExitingClub)
                .onChange(of: viewModel.isUserMember) { _, newValue in
                    if initialMembershipCheckComplete {
                        if newValue {
                            presentSuccessToast(message: "Successfully joined club")
                        } else {
                            presentSuccessToast(message: "Successfully exited club")
                        }
                    } else {
                        initialMembershipCheckComplete = true
                    }
                }
                .help(viewModel.isUserMember ? "Exit Club" : "Join Club")
                #else
                Menu {
                    if viewModel.isUserMember {
                        Button(role: .destructive, action: {
                            showingExitConfirmation = true
                        }) {
                            Label("Exit Club", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        Button(action: {
                            viewModel.joinClub(asProject: false)
                        }) {
                            Label("Join Club", systemImage: "person.badge.plus")
                        }
                        
                        Button(action: {
                            viewModel.joinClub(asProject: true)
                        }) {
                            Label("Join as Project", systemImage: "star.circle")
                        }
                    }
                } label: {
                    Image(systemName: viewModel.isUserMember ? "person.fill.checkmark" : "person.crop.circle.badge.plus")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(viewModel.isUserMember ? .green : .blue)
                        .opacity(viewModel.isJoiningClub || viewModel.isExitingClub ? 0.5 : 1.0)
                        .overlay {
                            if viewModel.isJoiningClub || viewModel.isExitingClub {
                                ProgressView()
                                    .controlSize(.mini)
                            }
                        }
                }
                .disabled(viewModel.isJoiningClub || viewModel.isExitingClub)
                .onChange(of: viewModel.isUserMember) { _, newValue in
                    if initialMembershipCheckComplete {
                        if newValue {
                            presentSuccessToast(message: "Successfully joined club")
                        } else {
                            presentSuccessToast(message: "Successfully exited club")
                        }
                    } else {
                        initialMembershipCheckComplete = true
                    }
                }
                #endif
            }
        }
    }
    
    private func presentSuccessToast(message: String) {
        let toast = ToastValue(
            icon: Image(systemName: "checkmark.circle").foregroundStyle(.green),
            message: message
        )
        presentToast(toast)
    }
    
    // MARK: - View Components
    
    private var selectionSection: some View {
        Section {
            Picker("Category", selection: $viewModel.selectedCategory) {
                #if targetEnvironment(macCatalyst)
                if viewModel.categories.isEmpty {
                    Text("Loading...").tag(nil as Category?)
                } else {
                    ForEach(viewModel.categories) { category in
                        Text(category.C_Category).tag(category as Category?)
                    }
                }
                #else
                if viewModel.selectedCategory == nil {
                    Text("Unavailable").tag(nil as Category?)
                }
                ForEach(viewModel.categories) { category in
                    Text(category.C_Category).tag(category as Category?)
                }
                #endif
            }
            .pickerStyle(MenuPickerStyle())
            //.pickerStyle(.segmented)
            .onChange(of: viewModel.selectedCategory) { oldValue, newValue in
                if let category = viewModel.selectedCategory {
                    viewModel.fetchGroups(for: category)
                }
            }
            
            Picker("Club", selection: $viewModel.selectedGroup) {
                #if targetEnvironment(macCatalyst)
                if viewModel.groups.isEmpty {
                    Text("Loading...").tag(nil as ClubGroup?)
                } else {
                    ForEach(viewModel.groups) { group in
                        Text(group.C_NameC).tag(group as ClubGroup?)
                    }
                }
                #else
                if viewModel.selectedGroup == nil {
                    Text("Unavailable").tag(nil as ClubGroup?)
                }
                ForEach(viewModel.groups) { group in
                    Text(group.C_NameC).tag(group as ClubGroup?)
                }
                #endif
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(viewModel.groups.isEmpty)
            .onChange(of: viewModel.selectedGroup) {
                handleGroupSelection()
            }
        }
    }
    
    private var emptyStateSection: some View {
        Group {
            if viewModel.categories.isEmpty && !viewModel.isLoading {
                emptyCategoriesView
            } else if viewModel.groups.isEmpty && viewModel.selectedCategory != nil && !viewModel.isLoading {
                emptyGroupsView
            }
        }
    }
    
    private var emptyCategoriesView: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
                
                Text("Club Information")
                    .font(.headline)
                
                Text("Select a category to view available clubs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    private var emptyGroupsView: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
                
                Text("No clubs available")
                    .font(.headline)
                
                Text("There are no clubs in this category")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    private var errorMessageView: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.errorMessage)
            }
        }
    }
    
    private var loadingSection: some View {
        Section {
            ClubSkeletonView()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: viewModel.isLoading)
    }
    
    private func clubInfoSection(groupInfo: GroupInfo) -> some View {
        Section(header: Text("About \(groupInfo.C_NameE)")) {
            ClubDetailView(
                groupInfo: groupInfo, 
                extractText: viewModel.extractText, 
                animateList: animateList
            )
        }
        .listSectionSpacing(.compact)
        .contentTransition(.opacity)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var memberSection: some View {
        Section(header: memberSectionHeader) {
            MembersListView(
                members: viewModel.members,
                isLoading: viewModel.isLoading,
                selectedGroup: viewModel.selectedGroup,
                animateList: animateList,
                fetchGroupInfo: viewModel.fetchGroupInfo
            )
        }
        .listSectionSpacing(.compact)
        .contentTransition(.opacity)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var memberSectionHeader: some View {
        HStack {
            Text("Members")
            if !viewModel.members.isEmpty {
                Text("(\(viewModel.members.count))")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
    }
    
    private var toolbarProgressView: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                withAnimation {
                    refreshButtonRotation += 360
                }
                
                // Store current selection before refresh
                let currentGroupId = viewModel.selectedGroup?.C_GroupsID
                
                if let category = viewModel.selectedCategory {
                    viewModel.fetchGroups(for: category)
                } else {
                    viewModel.fetchCategories()
                }
                
                if let group = viewModel.selectedGroup {
                    viewModel.fetchGroupInfo(for: group)
                }
                
                // Always preserve the group ID if available
                if let id = currentGroupId {
                    preservedGroupId = id
                }
                
                // Reset refreshing state after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    viewModel.refreshing = false
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(refreshButtonRotation))
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: refreshButtonRotation)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func onAppearSetup() {
        viewModel.fetchCategories()
        
        // Trigger animations after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateList = true
            }
        }
        
        #if targetEnvironment(macCatalyst)
        // Force a refresh on Mac Catalyst to avoid the "Unavailable" issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let category = viewModel.selectedCategory, viewModel.selectedGroup == nil {
                viewModel.fetchGroups(for: category)
            }
        }
        #endif
    }
    
    private func handleGroupSelection() {
        if let group = viewModel.selectedGroup {
            viewModel.fetchGroupInfo(for: group)
            // Reset animations to trigger again
            withAnimation(.easeOut(duration: 0.3)) {
                animateList = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateList = true
                }
            }
        }
    }
    
    private func handleLoadingChange(_ isLoading: Bool) {
        if (!isLoading && viewModel.groupInfo != nil) {
            // Reset and retrigger staggered animations when loading completes
            animateList = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateList = true
                }
            }
        }
    }
    
    private func handleRefresh() {
        // Pull to refresh with haptic feedback
        HapticManager.shared.playFeedback(.medium)
        
        viewModel.refreshing = true
        
        // Store current selection before refresh
        let currentGroupId = viewModel.selectedGroup?.C_GroupsID
        
        // If we have a specific club open, refresh it directly
        if let groupId = currentGroupId {
            // Use the direct method for more reliable refresh
            viewModel.fetchGroupInfoById(groupId)
        } else {
            // Otherwise, refresh the current view state
            if let category = viewModel.selectedCategory {
                viewModel.fetchGroups(for: category)
            } else {
                viewModel.fetchCategories()
            }
            
            if let group = viewModel.selectedGroup {
                viewModel.fetchGroupInfo(for: group)
            }
        }
        
        // Always preserve the group ID if available
        if let id = currentGroupId {
            preservedGroupId = id
        }
        
        // If we have a pending club ID from URL, preserve that too
        if let pendingId = viewModel.pendingClubId {
            preservedGroupId = pendingId
        }
        
        // Reset refreshing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            viewModel.refreshing = false
        }
    }
    
    // Add a new helper method to handle sharing
    private func shareClub(groupInfo: GroupInfo) {
        // Create a universal link for better compatibility
        let universalLinkString = "https://outspire.wrye.dev/app/club/\(groupInfo.C_GroupsID)"
        guard let url = URL(string: universalLinkString) else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // On iPad, set the popover presentation controller's source
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = rootViewController.view
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                activityViewController.popoverPresentationController?.permittedArrowDirections = []
            }
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

// MARK: - Extracted Subviews

struct ClubDetailView: View {
    let groupInfo: GroupInfo
    let extractText: (String) -> String?
    let animateList: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("Title", value: groupInfo.C_NameC)
                .offset(y: animateList ? 0 : 20)
                .opacity(animateList ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: animateList)
            
            Divider()
            
            LabeledContent("No", value: "\(groupInfo.C_GroupNo) (\(groupInfo.C_GroupsID))")
                .offset(y: animateList ? 0 : 20)
                .opacity(animateList ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2), value: animateList)
            
            if groupInfo.C_FoundTime != "0000-00-00 00:00:00" {
                Divider()
                
                LabeledContent("Founded", value: groupInfo.C_FoundTime)
                    .offset(y: animateList ? 0 : 20)
                    .opacity(animateList ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3), value: animateList)
            }
            
            descriptionView
        }
        .padding(.vertical, 8)
    }
    
    private var descriptionView: some View {
        Group {
            if let descriptionC = extractText(groupInfo.C_DescriptionC), 
                !descriptionC.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Divider()
                
                Text("\(descriptionC)")
                    .padding(.vertical, 5)
                    .offset(y: animateList ? 0 : 20)
                    .opacity(animateList ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.4), value: animateList)
            }
            
            if let descriptionE = extractText(groupInfo.C_DescriptionE), 
                !descriptionE.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if extractText(groupInfo.C_DescriptionC) != nil {
                    Divider()
                }
                
                Text("\(descriptionE)")
                    .padding(.vertical, 5)
                    .offset(y: animateList ? 0 : 20)
                    .opacity(animateList ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.5), value: animateList)
            }
        }
    }
}

struct MembersListView: View {
    @EnvironmentObject var sessionService: SessionService
    let members: [Member]
    let isLoading: Bool
    let selectedGroup: ClubGroup?
    let animateList: Bool
    let fetchGroupInfo: (ClubGroup) -> Void
    
    var body: some View {
        Group {
            if isLoading {
                memberLoadingView
            } else if members.isEmpty {
                emptyMembersView
            } else {
                membersList
            }
        }
    }
    
    private var memberLoadingView: some View {
        ForEach(0..<4, id: \.self) { _ in
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 18)
                    .frame(width: 120)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 18)
                    .frame(width: 60)
            }
            .padding(.vertical, 4)
        }
        .redacted(reason: .placeholder)
        .shimmering()
    }
    
    private var emptyMembersView: some View {
        if sessionService.isAuthenticated {
            Text("No members available, possibily dissolved.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        } else {
            Text("Available after signed in.")
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        }
    }
    
    private var membersList: some View {
        ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
            // Break down the complex member row into smaller components
            MemberRow(
                member: member,
                isCurrentUser: member.StudentID == sessionService.userInfo?.studentid,
                animateList: animateList,
                index: index
            )
        }
    }
}

// New component to simplify the complex member row
struct MemberRow: View {
    let member: Member
    let isCurrentUser: Bool
    let animateList: Bool
    let index: Int
    
    var body: some View {
        HStack(spacing: 10) {
            MemberInfo(
                member: member,
                isCurrentUser: isCurrentUser
            )
            
            Spacer()
            
            // Leadership star badge
            if member.LeaderYes == "2" || member.LeaderYes == "1" {
                Image(systemName: "star.fill")
                    .foregroundStyle(member.LeaderYes == "2" ? .red : .orange)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
        .offset(x: animateList ? 0 : 60)
        .opacity(animateList ? 1 : 0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.8)
            .delay(Double(index) * 0.04),
            value: animateList
        )
        .padding(.vertical, 4)
    }
}

// Further break down member info component
struct MemberInfo: View {
    let member: Member
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                // Member name
                Text(member.S_Name)
                    .font(.body)
                    .fontWeight(member.LeaderYes == "2" || member.LeaderYes == "1" ? .medium : .regular)
                    .foregroundStyle(isCurrentUser ? .blue : .primary)
                
                // Nickname if available
                if let nickname = member.S_Nickname, !nickname.isEmpty {
                    Text("(\(nickname))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // "You" badge for current user
                if isCurrentUser {
                    UserBadge()
                }
            }
            
            // Leadership badge
            if member.LeaderYes == "2" || member.LeaderYes == "1" {
                LeadershipBadge(isPresident: member.LeaderYes == "2")
            }
        }
    }
}

// Small components to further simplify
struct UserBadge: View {
    var body: some View {
        Text("You")
            .font(.caption)
            .foregroundStyle(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
    }
}

struct LeadershipBadge: View {
    let isPresident: Bool
    
    var body: some View {
        Text(isPresident ? "President" : "Vice President")
            .font(.caption)
            .foregroundStyle(isPresident ? .red : .orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(isPresident ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
            )
    }
}

// Club skeleton view
struct ClubSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Club info skeleton
            VStack(alignment: .leading, spacing: 12) {
                Text("Club Information")
                    .font(.headline)
                    .foregroundStyle(.clear)
                
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                            .frame(width: 80)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                            .frame(width: 140)
                    }
                }
                
                // Description skeleton
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 10)
            }
            .padding([.vertical], 8)
            
            // Member list skeleton
            VStack(alignment: .leading, spacing: 12) {
                Text("Members")
                    .font(.headline)
                    .foregroundStyle(.clear)
                
                ForEach(0..<5, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                            .frame(width: 120)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                            .frame(width: 80)
                    }
                }
            }
            .padding([.vertical], 8)
        }
        .redacted(reason: .placeholder)
        .shimmering()
        .padding([.vertical], 8)
    }
}
