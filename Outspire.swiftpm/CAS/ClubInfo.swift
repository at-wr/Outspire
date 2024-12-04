import SwiftUI
import SwiftSoup

struct ClubInfoView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    @State private var selectedCategory: Category? = nil
    @State private var selectedGroup: Group? = nil
    @State private var categories: [Category] = []
    @State private var groups: [Group] = []
    @State private var groupInfo: GroupInfo?
    @State private var members: [Member] = []
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select").tag(nil as Category?).selectionDisabled()
                        ForEach(categories, id: \.C_CategoryID) { category in
                            Text(category.C_Category).tag(category as Category?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedCategory) {
                        if let category = selectedCategory {
                            fetchGroups(for: category)
                        } else {
                            groups = []
                            selectedGroup = nil
                            groupInfo = nil
                            members = []
                        }
                    }
                    
                    if !groups.isEmpty {
                        Picker("Club Name", selection: $selectedGroup) {
                            Text("Select").tag(nil as Group?).selectionDisabled()
                            ForEach(groups, id: \.C_GroupsID) { group in
                                Text(group.C_NameC).tag(group as Group?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedGroup) {
                            if let group = selectedGroup {
                                fetchGroupInfo(for: group)
                            } else {
                                groupInfo = nil
                                members = []
                            }
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                if isLoading {
                    ProgressView()
                } else {
                    if let groupInfo = groupInfo {
                        Section(header: Text("About \(groupInfo.C_NameE)")) {
                            HStack {
                                Text("Title:")
                                    .foregroundStyle(.secondary)
                                Text("\(groupInfo.C_NameC)")
                            }
                            HStack {
                                Text("No:")
                                    .foregroundStyle(.secondary)
                                Text("\(groupInfo.C_GroupNo)")
                                Text("(\(groupInfo.C_GroupsID))")
                            }
                            
                            if groupInfo.C_FoundTime != "0000-00-00 00:00:00" {
                                HStack {
                                    Text("Found:")
                                        .foregroundStyle(.secondary)
                                    Text("\(groupInfo.C_FoundTime)")
                                }
                            }
                            
                            if let descriptionC = extractText(from: groupInfo.C_DescriptionC) {
                                Text("\(descriptionC)")
                            }
                            
                            if !groupInfo.C_DescriptionE.isEmpty, let descriptionE = extractText(from: groupInfo.C_DescriptionE) {
                                Text("\(descriptionE)")
                            }
                        }
                        
                        Section(header: Text("Members")) {
                            if members.isEmpty {
                                Text("No members available.")
                                    .foregroundColor(.secondary)
                            } else {
                                List(members, id: \.StudentID) { member in
                                    HStack {
                                        Text(member.S_Name)
                                        if let nickname = member.S_Nickname {
                                            Text("(\(nickname))")
                                                .foregroundColor(.secondary)
                                        }
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
            .contentMargins(.vertical, 20.0)
            .textSelection(.enabled)
            .navigationBarTitle("Club Info")
            .scrollDismissesKeyboard(.immediately)
            .onAppear(perform: fetchCategories)
        }
    }
    
    private func extractText(from html: String) -> String? {
        do {
            let doc: Document = try SwiftSoup.parse(html)
            let text = try doc.text()
            return text
        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }
    
    func fetchCategories() {
        guard let url = URL(string: "\(Configuration.baseURL)/php/cas_init_category_dropdown.php") else {
            errorMessage = "Invalid URL."
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.errorMessage = "\(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let categories = try JSONDecoder().decode([Category].self, from: data)
                    self.categories = categories
                } catch {
                    self.errorMessage = "Unable to parse categories: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchGroups(for category: Category) {
        guard let url = URL(string: "\(Configuration.baseURL)/php/cas_init_groups_dropdown.php") else {
            errorMessage = "Invalid URL."
            return
        }
        
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let sessionId = sessionManager.sessionId {
            Configuration.headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = Configuration.headers
        request.httpBody = "categoryid=\(category.C_CategoryID)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.errorMessage = "\(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let groups = try JSONDecoder().decode([Group].self, from: data)
                    self.groups = groups
                } catch {
                    self.errorMessage = "Unable to parse groups: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchGroupInfo(for group: Group) {
        guard let url = URL(string: "\(Configuration.baseURL)/php/cas_add_group_info.php") else {
            errorMessage = "Invalid URL."
            return
        }
        
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "groupid=\(group.C_GroupsID)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Request error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    // Debug Raw Output
                    if let rawJSON = String(data: data, encoding: .utf8) {
                        print("Raw JSON Response: \(rawJSON)")
                    }
                    
                    let response = try JSONDecoder().decode(GroupInfoResponse.self, from: data)
                    
                    if let fetchedGroup = response.groups.first {
                        self.groupInfo = fetchedGroup
                        self.members = response.gmember
                    } else {
                        self.errorMessage = "Group not found in response."
                    }
                    
                    // Debug Group Info Output
                    // print("Decoded Group Info: \(String(describing: self.groupInfo))")
                    // print("Decoded Members: \(self.members)")
                } catch {
                    self.errorMessage = "Unable to parse group info: \(error.localizedDescription)"
                    print("Decoding Error: \(error)")
                }
            }
        }.resume()
    }
}
