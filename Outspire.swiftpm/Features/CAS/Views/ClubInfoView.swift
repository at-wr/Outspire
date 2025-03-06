import SwiftUI

struct ClubInfoView: View {
    @StateObject private var viewModel = ClubInfoViewModel()
    @State private var animateList = false
    @State private var refreshButtonRotation = 0.0
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("Select").tag(nil as Category?)
                        ForEach(viewModel.categories) { category in
                            Text(category.C_Category).tag(category as Category?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.selectedCategory) {
                        if let category = viewModel.selectedCategory {
                            viewModel.fetchGroups(for: category)
                        }
                    }
                    
                    Picker("Club Name", selection: $viewModel.selectedGroup) {
                        Text("Select").tag(nil as ClubGroup?)
                        ForEach(viewModel.groups) { group in
                            Text(group.C_NameC).tag(group as ClubGroup?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(viewModel.groups.isEmpty)
                    .onChange(of: viewModel.selectedGroup) {
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
                }
                
                if viewModel.categories.isEmpty && !viewModel.isLoading {
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
                } else if viewModel.groups.isEmpty && viewModel.selectedCategory != nil && !viewModel.isLoading {
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
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut, value: viewModel.errorMessage)
                }
                
                if viewModel.isLoading && (viewModel.groupInfo == nil || !viewModel.refreshing) {
                    Section {
                        ClubSkeletonView()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isLoading)
                } else {
                    if let groupInfo = viewModel.groupInfo {
                        Section(header: Text("About \(groupInfo.C_NameE)")) {
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
                                
                                if let descriptionC = viewModel.extractText(from: groupInfo.C_DescriptionC), !descriptionC.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Divider()
                                    
                                    Text("\(descriptionC)")
                                        .padding(.vertical, 5)
                                        .offset(y: animateList ? 0 : 20)
                                        .opacity(animateList ? 1 : 0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.4), value: animateList)
                                }
                                
                                if let descriptionE = viewModel.extractText(from: groupInfo.C_DescriptionE), !descriptionE.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    if viewModel.extractText(from: groupInfo.C_DescriptionC) != nil {
                                        Divider()
                                    }
                                    
                                    Text("\(descriptionE)")
                                        .padding(.vertical, 5)
                                        .offset(y: animateList ? 0 : 20)
                                        .opacity(animateList ? 1 : 0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.5), value: animateList)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listSectionSpacing(.compact)
                        .contentTransition(.opacity)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        Section(header: 
                                    HStack {
                            Text("Members")
                            if !viewModel.members.isEmpty {
                                Text("(\(viewModel.members.count))")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                        }
                        ) {
                            if viewModel.isLoading {
                                VStack(spacing: 12) {
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
                                    }
                                }
                                .redacted(reason: .placeholder)
                                .shimmering()
                                .padding(.vertical, 8)
                            } else if viewModel.members.isEmpty {
                                Text("No members available.")
                                    .foregroundColor(.secondary)
                                    .transition(.opacity)
                                
                                // Debug button for developer use
#if DEBUG
                                Button("Reload Members") {
                                    if let group = viewModel.selectedGroup {
                                        viewModel.fetchGroupInfo(for: group)
                                    }
                                }
                                .font(.footnote)
#endif
                            } else {
                                ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                                    HStack {
                                        Text(member.S_Name)
                                            .fontWeight(member.LeaderYes == "2" || member.LeaderYes == "1" ? .medium : .regular)
                                        if let nickname = member.S_Nickname, !nickname.isEmpty {
                                            Text("(\(nickname))")
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if member.LeaderYes == "2" {
                                            Text("President")
                                                .foregroundColor(.red)
                                                .font(.subheadline)
                                        } else if member.LeaderYes == "1" {
                                            Text("Vice President")
                                                .foregroundColor(.orange)
                                                .font(.subheadline)
                                        }
                                    }
                                    .listRowBackground(Color.clear)
                                    .offset(x: animateList ? 0 : 100, y: 0)
                                    .opacity(animateList ? 1 : 0)
                                    .animation(
                                        .spring(response: 0.4, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.05), // Staggered animation
                                        value: animateList
                                    )
                                }
                            }
                        }
                        .listSectionSpacing(.compact)
                        .contentTransition(.opacity)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .contentMargins(.vertical, 10.0)
            .textSelection(.enabled)
            .navigationBarTitle("Club Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
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
            .scrollDismissesKeyboard(.immediately)
            .onAppear {
                viewModel.fetchCategories()
                
                // Trigger animations after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateList = true
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { isLoading in
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
            .animation(.spring(response: 0.4), value: viewModel.isLoading)
        }
        .refreshable {
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
}

// Club skeleton view for better loading visuals
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
            .padding(.vertical, 8)
            
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
            .padding(.vertical, 8)
        }
        .redacted(reason: .placeholder)
        .shimmering()
        .padding(.vertical, 8)
    }
}
