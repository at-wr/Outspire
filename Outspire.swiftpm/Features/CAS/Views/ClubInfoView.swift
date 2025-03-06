import SwiftUI

struct ClubInfoView: View {
    @StateObject private var viewModel = ClubInfoViewModel()
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("Select").tag(nil as Category?)
                        ForEach(viewModel.categories, id: \.C_CategoryID) { category in
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
                            Text("Select").tag(nil as Group?)
                            ForEach(viewModel.groups, id: \.C_GroupsID) { group in
                                Text(group.C_NameC).tag(group as Group?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.selectedGroup) {
                            if let group = viewModel.selectedGroup {
                                viewModel.fetchGroupInfo(for: group)
                            }
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading data...")
                } else {
                    if let groupInfo = viewModel.groupInfo {
                        Section(header: Text("About \(groupInfo.C_NameE)")) {
                            LabeledContent("Title", value: groupInfo.C_NameC)
                            LabeledContent("No", value: "\(groupInfo.C_GroupNo) (\(groupInfo.C_GroupsID))")
                            
                            if groupInfo.C_FoundTime != "0000-00-00 00:00:00" {
                                LabeledContent("Founded", value: groupInfo.C_FoundTime)
                            }
                            
                            if let descriptionC = viewModel.extractText(from: groupInfo.C_DescriptionC) {
                                Text("\(descriptionC)")
                                    .padding(.vertical, 5)
                            }
                            
                            if !groupInfo.C_DescriptionE.isEmpty, let descriptionE = viewModel.extractText(from: groupInfo.C_DescriptionE) {
                                Text("\(descriptionE)")
                                    .padding(.vertical, 5)
                            }
                        }
                        
                        Section(header: Text("Members")) {
                            if viewModel.members.isEmpty {
                                Text("No members available.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.members) { member in
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
                                }
                            }
                        }
                    }
                }
            }
            .contentMargins(.vertical, 10.0)
            .textSelection(.enabled)
            .navigationBarTitle("Club Info")
            .scrollDismissesKeyboard(.immediately)
            .onAppear(perform: viewModel.fetchCategories)
        }
    }
}