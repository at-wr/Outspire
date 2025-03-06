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
                    
                    if !viewModel.groups.isEmpty {
                        Picker("Club Name", selection: $viewModel.selectedGroup) {
                            Text("Select").tag(nil as ClubGroup?)
                            ForEach(viewModel.groups) { group in
                                Text(group.C_NameC).tag(group as ClubGroup?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
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
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut, value: viewModel.groups.isEmpty)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut, value: viewModel.errorMessage)
                }
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading data...")
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
                                
                                LabeledContent("No", value: "\(groupInfo.C_GroupNo) (\(groupInfo.C_GroupsID))")
                                    .offset(y: animateList ? 0 : 20)
                                    .opacity(animateList ? 1 : 0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2), value: animateList)
                                
                                if groupInfo.C_FoundTime != "0000-00-00 00:00:00" {
                                    LabeledContent("Founded", value: groupInfo.C_FoundTime)
                                        .offset(y: animateList ? 0 : 20)
                                        .opacity(animateList ? 1 : 0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3), value: animateList)
                                }
                                
                                if let descriptionC = viewModel.extractText(from: groupInfo.C_DescriptionC) {
                                    Text("\(descriptionC)")
                                        .padding(.vertical, 5)
                                        .offset(y: animateList ? 0 : 20)
                                        .opacity(animateList ? 1 : 0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.4), value: animateList)
                                }
                                
                                if !groupInfo.C_DescriptionE.isEmpty, let descriptionE = viewModel.extractText(from: groupInfo.C_DescriptionE) {
                                    Text("\(descriptionE)")
                                        .padding(.vertical, 5)
                                        .offset(y: animateList ? 0 : 20)
                                        .opacity(animateList ? 1 : 0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.5), value: animateList)
                                }
                            }
                        }
                        .contentTransition(.opacity)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        Section(header: Text("Members")) {
                            if viewModel.members.isEmpty {
                                Text("No members available.")
                                    .foregroundColor(.secondary)
                                    .transition(.opacity)
                            } else {
                                ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                                    HStack {
                                        Text(member.S_Name)
                                        if let nickname = member.S_Nickname {
                                            Text("(\(nickname))")
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if member.LeaderYes == "2" {
                                            Text("社长")
                                                .foregroundColor(.red)
                                        } else if member.LeaderYes == "1" {
                                            Text("副社")
                                                .foregroundColor(.orange)
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
            
            if let category = viewModel.selectedCategory {
                viewModel.fetchGroups(for: category)
            } else {
                viewModel.fetchCategories()
            }
            
            if let group = viewModel.selectedGroup {
                viewModel.fetchGroupInfo(for: group)
            }
        }
    }
}