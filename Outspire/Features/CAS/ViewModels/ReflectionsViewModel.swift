import SwiftUI

/// ViewModel for managing reflections list and deletion in CAS feature.
enum ReflectionGroup: Identifiable, Hashable {
    case club(ClubGroup)
    case noGroup(NoGroup)

    var id: String {
        switch self {
        case .club(let group): return group.C_GroupsID
        case .noGroup(let group): return group.C_GroupsID
        }
    }

    var displayName: String {
        switch self {
        case .club(let group):
            if !group.C_NameE.isEmpty {
                return group.C_NameE
            } else {
                return group.C_NameC
            }
        case .noGroup(let group):
            if !group.C_NameE.isEmpty {
                return group.C_NameE
            } else {
                return group.C_NameC
            }
        }
    }
}

class ReflectionsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var groups: [ReflectionGroup] = []
    @Published var reflections: [Reflection] = []
    @Published var selectedGroupId: String = ""
    @Published var isLoadingGroups = false
    @Published var isLoadingReflections = false
    @Published var errorMessage: String?
    @Published var showingDeleteConfirmation = false
    @Published var reflectionToDelete: Reflection?

    private let sessionService = SessionService.shared

    // MARK: - Fetch Groups
    func fetchGroups(forceRefresh: Bool = false) {
        if !groups.isEmpty && !forceRefresh { return }
        isLoadingGroups = true
        errorMessage = nil

        NetworkService.shared.request(
            endpoint: "cas_add_mygroups_dropdown.php",
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<GroupDropdownResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoadingGroups = false
                switch result {
                case .success(let response):
                    var combined: [ReflectionGroup] = []
                    if let nogroups = response.nogroups {
                        combined.append(contentsOf: nogroups.map { .noGroup($0) })
                    }
                    combined.append(contentsOf: response.groups.map { .club($0) })
                    self?.groups = combined
                    if self?.selectedGroupId.isEmpty == true,
                       let first = combined.first {
                        self?.selectedGroupId = first.id
                        self?.fetchReflections()
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Fetch Reflections
    func fetchReflections(forceRefresh: Bool = false) {
        guard !selectedGroupId.isEmpty else {
            errorMessage = "Please select a group."
            return
        }
        if isLoadingReflections && !forceRefresh { return }
        isLoadingReflections = true
        errorMessage = nil

        NetworkService.shared.fetchReflections(groupID: selectedGroupId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingReflections = false
                switch result {
                case .success(let response):
                    self?.reflections = response.reflection
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Delete Reflection
    func deleteReflection(_ reflection: Reflection) {
        reflectionToDelete = reflection
        showingDeleteConfirmation = true
    }

    func confirmDelete() {
        guard let reflection = reflectionToDelete else { return }
        isLoadingReflections = true
        errorMessage = nil

        NetworkService.shared.deleteReflection(reflectionID: reflection.C_RefID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingReflections = false
                self?.showingDeleteConfirmation = false

                switch result {
                case .success(let status):
                    if status.status == "ok" {
                        self?.reflections.removeAll { $0.C_RefID == reflection.C_RefID }
                    } else {
                        self?.errorMessage = status.status
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
                self?.reflectionToDelete = nil
            }
        }
    }
}
