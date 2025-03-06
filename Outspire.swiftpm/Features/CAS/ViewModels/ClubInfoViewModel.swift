import SwiftUI
import SwiftSoup

class ClubInfoViewModel: ObservableObject {
    @Published var selectedCategory: Category? = nil
    @Published var selectedGroup: Group? = nil
    @Published var categories: [Category] = []
    @Published var groups: [Group] = []
    @Published var groupInfo: GroupInfo?
    @Published var members: [Member] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
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
        ) { [weak self] (result: Result<[Group], NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let groups):
                self.groups = groups
            case .failure(let error):
                self.errorMessage = "Unable to load groups: \(error.localizedDescription)"
            }
        }
    }

    func fetchGroupInfo(for group: Group) {
        isLoading = true
        errorMessage = nil
        
        let parameters = ["groupid": group.C_GroupsID]
        
        NetworkService.shared.request(
            endpoint: "cas_add_group_info.php",
            parameters: parameters
        ) { [weak self] (result: Result<GroupInfoResponse, NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let response):
                if let fetchedGroup = response.groups.first {
                    self.groupInfo = fetchedGroup
                    self.members = response.gmember
                } else {
                    self.errorMessage = "Group info not found in response."
                }
            case .failure(let error):
                self.errorMessage = "Unable to load group info: \(error.localizedDescription)"
            }
        }
    }
    
    func extractText(from html: String) -> String? {
        do {
            let doc: Document = try SwiftSoup.parse(html)
            let text = try doc.text()
            return text
        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }
}
