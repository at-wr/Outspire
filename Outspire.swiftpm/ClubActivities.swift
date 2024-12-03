import SwiftUI

struct ClubActivitiesView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    @State private var groups: [Group] = []
    @State private var activities: [ActivityRecord] = []
    @State private var selectedGroupId: String = ""
    @State private var showingAddRecordSheet = false
    @State private var errorMessage: String?
    @State private var isLoadingGroups: Bool = false
    @State private var isLoadingActivities: Bool = false
    @State private var showingDeleteConfirmation = false
    @State private var recordToDelete: ActivityRecord?
    
    var body: some View {
        VStack {
            Form {
                if groups.isEmpty {
                    if isLoadingGroups {
                        ProgressView("Loading Groups...")
                    } else {
                        Text("No groups available.")
                            .foregroundColor(.red)
                    }
                } else {
                    Picker("Select Group", selection: $selectedGroupId) {
                        ForEach(groups) { group in
                            Text(group.C_NameE).tag(group.C_GroupsID)
                        }
                    }
                    .onChange(of: selectedGroupId) {
                        fetchActivityRecords()
                    }
                    
                    List {
                        ForEach($activities, id: \.C_ARecordID) { $activity in // 注意这里使用 $activity
                            VStack(alignment: .leading) {
                                Text("\(activity.C_Theme)")
                                    .fontWeight(.semibold)
                                
                                Text("Date: \(activity.C_Date)")
                                    .foregroundStyle(.secondary)
                                    .contentMargins(.top, 4)
                                
                                HStack() {
                                    Text("C: \(activity.C_DurationC)")
                                        .foregroundStyle(.windowBackground)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 0.6)
                                        .background(activity.C_DurationC == "0.0" ? .gray : .red)
                                        .clipShape(.capsule)
                                    
                                    Text("A: \(activity.C_DurationA)")
                                        .foregroundStyle(.windowBackground)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 0.6)
                                        .background(activity.C_DurationA == "0.0" ? .gray : .mint)
                                        .clipShape(.capsule)
                                    
                                    Text("S: \(activity.C_DurationS)")
                                        .foregroundStyle(.windowBackground)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 0.6)
                                        .background(activity.C_DurationS == "0.0" ? .gray : .indigo)
                                        .clipShape(.capsule)
                                }
                                
                                Text("\(activity.C_Reflection)")
                                    .foregroundColor(.primary)
                                    .contentMargins(.top, 15)
                            }
                            .padding(.bottom, 10)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    recordToDelete = activity // 这里使用解包后的 activity
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    copyActivityToClipboard(activity) // 这里使用解包后的 activity
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red)
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
                if let userId = sessionManager.userInfo?.studentid {
                    AddRecordSheet(
                        availableGroups: groups,
                        loggedInStudentId: userId,
                        onSave: { fetchActivityRecords() }
                    )
                } else {
                    Text("Unable to retrieve user ID.")
                }
            }
            .actionSheet(isPresented: $showingDeleteConfirmation) {
                ActionSheet(
                    title: Text("Delete Record"),
                    message: Text("Are you sure you want to delete this record?"),
                    buttons: [
                        .destructive(Text("Delete")) {
                            if let record = recordToDelete {
                                deleteRecord(record: record)
                                recordToDelete = nil
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .onAppear(perform: fetchGroups)
        }
    }
    
    func fetchGroups() {
        isLoadingGroups = true
        guard let url = URL(string: "\(Configuration.baseURL)/php/cas_add_mygroups_dropdown.php") else {
            errorMessage = "Invalid URL."
            isLoadingGroups = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let sessionId = sessionManager.sessionId {
            Configuration.headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = Configuration.headers
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoadingGroups = false
                if let error = error {
                    self.errorMessage = "\(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(GroupDropdownResponse.self, from: data)
                    self.groups = response.groups
                    if let firstGroup = self.groups.first {
                        self.selectedGroupId = firstGroup.C_GroupsID
                        fetchActivityRecords()
                    }
                } catch {
                    self.errorMessage = "Unable to parse groups: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchActivityRecords() {
        guard !selectedGroupId.isEmpty else {
            errorMessage = "Please select a group."
            return
        }
        
        isLoadingActivities = true
        guard let url = URL(string: "\(Configuration.baseURL)/php/cas_add_record_info.php") else {
            errorMessage = "Invalid URL."
            isLoadingActivities = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let sessionId = sessionManager.sessionId {
            Configuration.headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = Configuration.headers
        request.httpBody = "groupid=\(selectedGroupId)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoadingActivities = false
                if let error = error {
                    self.errorMessage = "\(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ActivityResponse.self, from: data)
                    self.activities = response.casRecord
                } catch {
                    self.errorMessage = "Unable to parse activities: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func deleteRecord(record: ActivityRecord) {
        guard let url = URL(string: "\(Configuration.baseURL)/php/cas_delete_record_info.php") else {
            errorMessage = "Invalid URL."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let sessionId = sessionManager.sessionId {
            Configuration.headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = Configuration.headers
        request.httpBody = "recordid=\(record.C_ARecordID)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode([String: String].self, from: data)
                    if response["status"] == "ok" {
                        withAnimation {
                            self.activities.removeAll { $0.C_ARecordID == record.C_ARecordID }
                        }
                    } else {
                        self.errorMessage = response["status"]
                    }
                } catch {
                    self.errorMessage = "Unable to delete record: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func copyActivityToClipboard(_ activity: ActivityRecord) {
        let activityInfo = """
        Theme: \(activity.C_Theme)
        Date: \(activity.C_Date)
        Duration: C: \(activity.C_DurationC), A: \(activity.C_DurationA), S: \(activity.C_DurationS)
        Reflection: \(activity.C_Reflection)
        """
        UIPasteboard.general.string = activityInfo
        errorMessage = "Activity copied to clipboard!"
    }
}
