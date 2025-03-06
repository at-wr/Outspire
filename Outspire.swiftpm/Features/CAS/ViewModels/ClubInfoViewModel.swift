import SwiftUI
import SwiftSoup

class ClubInfoViewModel: ObservableObject {
    @Published var selectedCategory: Category? = nil
    @Published var selectedGroup: ClubGroup? = nil
    @Published var categories: [Category] = []
    @Published var groups: [ClubGroup] = []
    @Published var groupInfo: GroupInfo?
    @Published var members: [Member] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var refreshing: Bool = false
    
    private let sessionService = SessionService.shared
    
    func fetchCategories() {
        isLoading = true
        errorMessage = nil
        
        NetworkService.shared.request(
            endpoint: "cas_init_category_dropdown.php",
            method: .get
        ) { [weak self] (result: Result<[Category], NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let categories):
                self.categories = categories
                
                // Auto-select first category if none selected
                if self.categories.count > 0 && self.selectedCategory == nil {
                    self.selectedCategory = categories[0]
                    self.fetchGroups(for: categories[0])
                }
                
            case .failure(let error):
                self.errorMessage = "Unable to load categories: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchGroups(for category: Category) {
        isLoading = true
        errorMessage = nil
        
        let parameters = ["categoryid": category.C_CategoryID]
        
        NetworkService.shared.request(
            endpoint: "cas_init_groups_dropdown.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[ClubGroup], NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let groups):
                self.groups = groups
                
                // When category changes, reset the selectedGroup and show the "Select" option
                self.selectedGroup = nil
                
                // Auto-select first group if available
                if !groups.isEmpty {
                    // Use a small delay to ensure UI updates properly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.selectedGroup = groups[0]
                        self.fetchGroupInfo(for: groups[0])
                    }
                }
                
            case .failure(let error):
                self.errorMessage = "Unable to load groups: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchGroupInfo(for group: ClubGroup) {
        isLoading = true
        errorMessage = nil
        
        let parameters = ["groupid": group.C_GroupsID]
        
        NetworkService.shared.request(
            endpoint: "cas_add_group_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<GroupInfoResponse, NetworkError>) in
            guard let self = self else { return }
            
            // Add a small delay to ensure UI transitions feel natural
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if let fetchedGroup = response.groups.first {
                        self.groupInfo = fetchedGroup
                        self.members = response.gmember
                        
                        // Debug logging for member data
                        print("Loaded \(response.gmember.count) members for group \(group.C_NameC)")
                        if response.gmember.isEmpty {
                            print("Member list is empty from API response")
                            
                            // Retry with session ID if members list is empty
                            // This is a workaround for possible session/auth issues
                            if let sessionId = self.sessionService.sessionId {
                                print("Retrying with session ID: \(sessionId)")
                                self.retryFetchWithSession(parameters: parameters)
                            }
                        }
                    } else {
                        self.errorMessage = "Group info not found in response."
                    }
                case .failure(let error):
                    self.errorMessage = "Unable to load group info: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func retryFetchWithSession(parameters: [String: String]) {
        print("Retrying fetch with explicit session...")
        
        NetworkService.shared.request(
            endpoint: "cas_add_group_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<GroupInfoResponse, NetworkError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response.gmember.count > 0 {
                    print("Retry successful, got \(response.gmember.count) members")
                    self.members = response.gmember
                } else {
                    print("Retry failed, still no members")
                }
            case .failure(let error):
                print("Retry failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    func extractText(from html: String) -> String? {
        do {
            let doc: Document = try SwiftSoup.parse(html)
            let text = try doc.text()
            
            // Return nil if text is empty or only whitespace/newlines
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : text
        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }
}
