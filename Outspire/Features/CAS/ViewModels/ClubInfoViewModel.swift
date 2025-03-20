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
    @Published var isJoiningClub: Bool = false
    @Published var isExitingClub: Bool = false
    @Published var isUserMember: Bool = false
    @Published var pendingClubId: String? = nil
    @Published var isFromURLNavigation: Bool = false
    
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
                    #if targetEnvironment(macCatalyst)
                    // In Mac Catalyst, select with a slight delay to allow UI update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.selectedCategory = categories[1]
                        self.fetchGroups(for: categories[1])
                    }
                    #else
                    self.selectedCategory = categories[1]
                    self.fetchGroups(for: categories[1])
                    #endif
                }
                
            case .failure(let error):
                self.errorMessage = "Unable to load categories: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchGroups(for category: Category) {
        isLoading = true
        errorMessage = nil
        
        // Store the current selection before fetching new groups
        let previousSelection = selectedGroup?.C_GroupsID
        
        // Track if we're in the middle of a URL navigation
        let isNavigatingFromURL = pendingClubId != nil || isFromURLNavigation
        
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
                
                // Check for pending club ID from URL scheme first
                if let pendingId = self.pendingClubId, 
                   let targetGroup = groups.first(where: { $0.C_GroupsID == pendingId }) {
                    print("Found pending club with ID: \(pendingId)")
                    self.selectedGroup = targetGroup
                    self.fetchGroupInfo(for: targetGroup)
                    self.pendingClubId = nil
                    self.isFromURLNavigation = true
                    
                    // Schedule to reset the URL navigation flag after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isFromURLNavigation = false
                    }
                    return
                }
                
                // If we have a pending ID but didn't find it in current category,
                // and we haven't searched all categories yet, try the next one
                if let pendingId = self.pendingClubId,
                   self.categories.count > 0 {
                    // Try the next category
                    let currentCategoryIndex = self.categories.firstIndex(where: { $0.C_CategoryID == category.C_CategoryID }) ?? -1
                    if currentCategoryIndex < self.categories.count - 1 {
                        // There's another category to try
                        let nextCategoryIndex = currentCategoryIndex + 1
                        print("Club not found in current category, trying the next category")
                        DispatchQueue.main.async {
                            self.selectedCategory = self.categories[nextCategoryIndex]
                            self.fetchGroups(for: self.categories[nextCategoryIndex])
                        }
                        return
                    } else {
                        // We've tried all categories and still haven't found the club
                        print("Club with ID \(pendingId) not found in any category")
                        self.pendingClubId = nil
                        self.isFromURLNavigation = false
                        self.errorMessage = "Club not found in any category"
                    }
                }
                
                // Try to preserve previous selection
                if self.isFromURLNavigation {
                    // Don't change selection if we're coming from URL navigation
                    print("Keeping current selection due to URL navigation")
                    return
                } else if let previousId = previousSelection,
                         let previousGroup = groups.first(where: { $0.C_GroupsID == previousId }) {
                    self.selectedGroup = previousGroup
                    self.fetchGroupInfo(for: previousGroup)
                    return
                }
                
                // Only apply auto-selection if we're not in the middle of a URL navigation
                if !isNavigatingFromURL {
                    #if targetEnvironment(macCatalyst)
                    // On Mac Catalyst, immediately set selection to avoid "Unavailable" display
                    if self.selectedGroup == nil && !groups.isEmpty {
                        // Use main queue to ensure proper UI update
                        DispatchQueue.main.async {
                            self.selectedGroup = groups[0]
                            self.fetchGroupInfo(for: groups[0])
                        }
                    }
                    #else
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
                    #endif
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
                        
                        // Check if the current user is a member of this club
                        self.checkUserMembership()
                        
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

    // Check if current user is a member of this club
    private func checkUserMembership() {
        guard sessionService.isAuthenticated,
              let currentUserId = sessionService.userInfo?.studentid else {
            isUserMember = false
            return
        }
        
        isUserMember = members.contains { member in
            member.StudentID == currentUserId
        }
    }
    
    func joinClub(asProject: Bool) {
        guard sessionService.isAuthenticated,
              let currentGroup = selectedGroup else {
            errorMessage = "You need to be signed in and have a club selected"
            return
        }
        
        isJoiningClub = true
        
        let parameters = [
            "groupid": currentGroup.C_GroupsID,
            "projYes": asProject ? "1" : "0"
        ]
        
        NetworkService.shared.request(
            endpoint: "cas_save_member_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[String: String], NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isJoiningClub = false
                
                switch result {
                case .success(let response):
                    if response["status"] == "ok" || response["status"] == nil {
                        // Refresh club info to update membership status
                        if let currentGroup = self.selectedGroup {
                            self.fetchGroupInfo(for: currentGroup)
                        }
                        
                        // Clear club activities cache to ensure fresh data on next view
                        CacheManager.clearClubActivitiesCache()
                    } else {
                        self.errorMessage = response["status"] ?? "Failed to join club"
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to join club: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func exitClub() {
        guard sessionService.isAuthenticated,
              let currentGroup = selectedGroup else {
            errorMessage = "You need to be signed in and have a club selected"
            return
        }
        
        isExitingClub = true
        
        let parameters = ["groupid": currentGroup.C_GroupsID]
        
        NetworkService.shared.request(
            endpoint: "cas_delete_member_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[String: String], NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isExitingClub = false
                
                switch result {
                case .success(let response):
                    if response["status"] == "ok" || response["status"] == nil {
                        // Refresh club info to update membership status
                        if let currentGroup = self.selectedGroup {
                            self.fetchGroupInfo(for: currentGroup)
                        }
                        
                        // Clear club activities cache to ensure fresh data on next view
                        CacheManager.clearClubActivitiesCache()
                    } else {
                        self.errorMessage = response["status"] ?? "Failed to exit club"
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to exit club: \(error.localizedDescription)"
                }
            }
        }
    }

    func extractText(from html: String) -> String? {
        do {
            let doc: Document = try SwiftSoup.parse(html)
            
            // Remove <a> Tags
            // lol this is for you, q1zhen
            let links: Elements = try doc.select("a")
            for link in links {
                try link.remove()
            }
            
            // Trim Texts
            let text = try doc.text()
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : text
        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }
    
    // Add a method to handle URL navigation requests
    func navigateToClubById(_ clubId: String) {
        print("Attempting to navigate to club ID: \(clubId)")
        
        // Cancel any previous URL navigation that might be in progress
        if pendingClubId != nil && pendingClubId != clubId {
            print("Cancelling previous navigation to \(pendingClubId!), now navigating to \(clubId)")
        }
        
        // Set URL navigation flag
        isFromURLNavigation = true
        
        // Reset any existing club info to prevent UI confusion during navigation
        if selectedGroup?.C_GroupsID != clubId {
            groupInfo = nil
            members = []
        }
        
        // First, check if we already have the groups loaded
        if let targetGroup = groups.first(where: { $0.C_GroupsID == clubId }) {
            print("Found club with ID: \(clubId) in current groups")
            self.selectedGroup = targetGroup
            self.fetchGroupInfo(for: targetGroup)
            
            // Schedule to reset the URL navigation flag after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isFromURLNavigation = false
            }
        } else {
            // Store the ID to check after groups are loaded
            print("Club with ID: \(clubId) not found in current groups, storing as pending")
            self.pendingClubId = clubId
            
            // If categories are loaded, start from the first category and try each one
            if !categories.isEmpty {
                print("Starting category search from the beginning")
                self.selectedCategory = categories[0]  // Start with the first category
                self.fetchGroups(for: categories[0])
            } else {
                print("Fetching categories first")
                self.fetchCategories()
            }
        }
    }
}
