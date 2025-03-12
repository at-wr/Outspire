import SwiftUI

struct ClubInfoView: View {
    @StateObject private var viewModel = ClubInfoViewModel()
    @State private var animateList = false
    @State private var refreshButtonRotation = 0.0
    
    
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
                toolbarProgressView
                refreshButton
            }
            .scrollDismissesKeyboard(.immediately)
            .onAppear(perform: onAppearSetup)
            .onChange(of: viewModel.isLoading) { oldValue, newValue in
                handleLoadingChange(newValue)
            } // use this to fix the stupid iOS 17 deprecation warning
            .animation(.spring(response: 0.4), value: viewModel.isLoading)
        }
        .refreshable {
            handleRefresh()
        }
    }
    
    // MARK: - View Components
    
    private var selectionSection: some View {
        Section {
            Picker("Category", selection: $viewModel.selectedCategory) {
                if viewModel.selectedCategory == nil {
                    Text("Unavailable").tag(nil as Category?)
                }
                ForEach(viewModel.categories) { category in
                    Text(category.C_Category).tag(category as Category?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            //.pickerStyle(.segmented)
            .onChange(of: viewModel.selectedCategory) {
                if let category = viewModel.selectedCategory {
                    viewModel.fetchGroups(for: category)
                }
            }
            
            Picker("Club", selection: $viewModel.selectedGroup) {
                if viewModel.selectedGroup == nil {
                    Text("Unvailable").tag(nil as ClubGroup?)
                }
                ForEach(viewModel.groups) { group in
                    Text(group.C_NameC).tag(group as ClubGroup?)
                }
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
                
                if viewModel.selectedCategory != nil {
                    viewModel.fetchGroups(for: viewModel.selectedCategory!)
                } else {
                    viewModel.fetchCategories()
                }
                
                if viewModel.selectedGroup != nil {
                    viewModel.fetchGroupInfo(for: viewModel.selectedGroup!)
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
        if !isLoading && viewModel.groupInfo != nil {
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
        
        if let category = viewModel.selectedCategory {
            viewModel.fetchGroups(for: category)
        } else {
            viewModel.fetchCategories()
        }
        
        if let group = viewModel.selectedGroup {
            viewModel.fetchGroupInfo(for: group)
        }
        
        // Reset refreshing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            viewModel.refreshing = false
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
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(member.S_Name)
                            .font(.body)
                            .fontWeight(member.LeaderYes == "2" || member.LeaderYes == "1" ? .medium : .regular)
                        
                        if let nickname = member.S_Nickname, !nickname.isEmpty {
                            Text("(\(nickname))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if member.LeaderYes == "2" || member.LeaderYes == "1" {
                        Text(member.LeaderYes == "2" ? "President" : "Vice President")
                            .font(.caption)
                            .foregroundStyle(member.LeaderYes == "2" ? .red : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(member.LeaderYes == "2" ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
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
