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
                    print("Found pending club with ID: \(pendingId) in category \(category.C_Category)")
                    self.selectedGroup = targetGroup
                    self.fetchGroupInfo(for: targetGroup)
                    self.pendingClubId = nil
                    
                    // Keep isFromURLNavigation true while we're fetching group info
                    // Will be reset in fetchGroupInfo completion
                    
                    return
                }
                
                // If we have a pending ID but didn't find it in current category,
                // try the next one systematically
                if let pendingId = self.pendingClubId {
                    let currentCategoryIndex = self.categories.firstIndex(where: { $0.C_CategoryID == category.C_CategoryID }) ?? -1
                    if currentCategoryIndex < self.categories.count - 1 {
                        // Try the next category
                        let nextCategoryIndex = currentCategoryIndex + 1
                        print("Club \(pendingId) not found in \(category.C_Category), trying \(self.categories[nextCategoryIndex].C_Category)")
                        DispatchQueue.main.async {
                            self.selectedCategory = self.categories[nextCategoryIndex]
                            self.fetchGroups(for: self.categories[nextCategoryIndex])
                        }
                        return
                    } else {
                        // We've searched all categories and didn't find the club
                        print("Club \(pendingId) not found in any category after complete search")
                        self.pendingClubId = nil
                        self.isFromURLNavigation = false
                        self.errorMessage = "Club not found. It may have been removed or you may not have access."
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
                self.isFromURLNavigation = false  // Reset navigation flag when fetch completes
                
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
        
        let newMembershipStatus = members.contains { member in
            member.StudentID == currentUserId
        }
        
        // Only update if there's a change to avoid triggering onChange unnecessarily
        if isUserMember != newMembershipStatus {
            isUserMember = newMembershipStatus
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
        print("Navigating to club ID: \(clubId)")
        
        // Reset any existing club info to prevent UI confusion
        if selectedGroup?.C_GroupsID != clubId {
            groupInfo = nil
            members = []
        }
        
        // Set URL navigation flags
        isFromURLNavigation = true
        
        // Direct API approach first - most robust method
        fetchGroupInfoById(clubId)
    }
    
    // Add a new method to directly fetch club info by ID
    func fetchGroupInfoById(_ clubId: String) {
        isLoading = true
        errorMessage = nil
        
        let parameters = ["groupid": clubId]
        
        NetworkService.shared.request(
            endpoint: "cas_add_group_info.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<GroupInfoResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let fetchedGroup = response.groups.first {
                        // We found the club directly! Set its info
                        self.groupInfo = fetchedGroup
                        self.members = response.gmember
                        
                        // Create a ClubGroup from the GroupInfo for selection
                        let group = ClubGroup(
                            C_GroupsID: fetchedGroup.C_GroupsID,
                            C_GroupNo: fetchedGroup.C_GroupNo,
                            C_NameC: fetchedGroup.C_NameC,
                            C_NameE: fetchedGroup.C_NameE
                        )
                        
                        // Find and select the correct category
                        if !fetchedGroup.C_CategoryID.isEmpty,
                           let category = self.categories.first(where: { $0.C_CategoryID == fetchedGroup.C_CategoryID }) {
                            self.selectedCategory = category
                            
                            // Fetch all groups in this category to populate the dropdown
                            // but don't wait for this to display club info
                            self.fetchGroupsForCategory(category, preselectedGroupId: clubId)
                        } else if self.categories.isEmpty {
                            // Categories not loaded yet, fetch them
                            self.fetchCategoriesWithPreselection(clubId: clubId, categoryId: fetchedGroup.C_CategoryID)
                        }
                        
                        // Set the club as selected even before we have the full groups list
                        self.selectedGroup = group
                        
                        // Check membership status
                        self.checkUserMembership()
                        
                        // Clear pending navigation flags
                        self.pendingClubId = nil
                        self.isFromURLNavigation = false
                        self.isLoading = false
                    } else {
                        // The API returned success but no club data
                        self.isLoading = false
                        self.errorMessage = "Club information not available"
                        self.pendingClubId = nil
                        self.isFromURLNavigation = false
                    }
                case .failure(let error):
                    // API request failed
                    self.isLoading = false
                    self.errorMessage = "Failed to load club: \(error.localizedDescription)"
                    
                    // If we have categories, try the fallback search approach
                    if !self.categories.isEmpty {
                        print("Direct club fetch failed, trying category search as fallback")
                        self.pendingClubId = clubId
                        self.searchClubInCategories(clubId: clubId)
                    } else {
                        // Load categories first, then will try search
                        self.pendingClubId = clubId
                        self.fetchCategories()
                    }
                }
            }
        }
    }
    
    // Helper method to fetch groups for a category with a preselected club
    private func fetchGroupsForCategory(_ category: Category, preselectedGroupId: String) {
        let parameters = ["categoryid": category.C_CategoryID]
        
        NetworkService.shared.request(
            endpoint: "cas_init_groups_dropdown.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[ClubGroup], NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let groups):
                    self.groups = groups
                    
                    // If we already have a group selected, ensure it's in the list
                    if self.selectedGroup?.C_GroupsID == preselectedGroupId {
                        // Find a more complete version of the group in the loaded groups
                        if let fullGroup = groups.first(where: { $0.C_GroupsID == preselectedGroupId }) {
                            self.selectedGroup = fullGroup
                        }
                    }
                case .failure(let error):
                    print("Failed to load groups for category: \(error.localizedDescription)")
                    // Don't set error message here as we already have the club info displayed
                }
            }
        }
    }
    
    // Helper to fetch categories with a preselection
    private func fetchCategoriesWithPreselection(clubId: String, categoryId: String?) {
        NetworkService.shared.request(
            endpoint: "cas_init_category_dropdown.php",
            method: .get
        ) { [weak self] (result: Result<[Category], NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let categories):
                    self.categories = categories
                    
                    // Select the right category if we know it
                    if let categoryId = categoryId,
                       let category = categories.first(where: { $0.C_CategoryID == categoryId }) {
                        self.selectedCategory = category
                        self.fetchGroupsForCategory(category, preselectedGroupId: clubId)
                    }
                case .failure:
                    // Don't update error - we already have the club info displayed
                    print("Failed to load categories after direct club fetch")
                }
            }
        }
    }
    
    // Fallback method to search for a club across all categories
    private func searchClubInCategories(clubId: String) {
        guard !categories.isEmpty else {
            // Can't search without categories
            self.fetchCategories()
            return
        }
        
        print("Starting systematic search for club \(clubId) across all categories")
        
        // Start with the first category
        self.selectedCategory = categories[0]
        self.fetchGroups(for: categories[0])
    }
}
