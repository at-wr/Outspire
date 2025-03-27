import SwiftUI
import Combine

class AddRecordViewModel: ObservableObject {
    @Published var selectedGroupId: String = ""
    @Published var activityDate = Date()
    @Published var activityTitle: String = ""
    @Published var durationC: Int = 0
    @Published var durationA: Int = 0
    @Published var durationS: Int = 0
    @Published var activityDescription: String = ""
    @Published var errorMessage: String?

    let availableGroups: [ClubGroup]
    let loggedInStudentId: String
    let onSave: () -> Void

    private let sessionService = SessionService.shared
    private static var cachedFormData: FormCache?
    private var cancellables = Set<AnyCancellable>()

    // Store form data for persistent recovery
    struct FormCache {
        let groupId: String
        let date: Date
        let title: String
        let durationC: Int
        let durationA: Int
        let durationS: Int
        let description: String
    }

    var totalDuration: Int {
        durationC + durationA + durationS
    }

    // Calculate word count for the description
    var descriptionWordCount: Int {
        activityDescription.isEmpty ? 0 : activityDescription.split(separator: " ").count
    }

    init(availableGroups: [ClubGroup], loggedInStudentId: String, onSave: @escaping () -> Void) {
        self.availableGroups = availableGroups
        self.loggedInStudentId = loggedInStudentId
        self.onSave = onSave

        // Try to restore from cache first
        if let cache = AddRecordViewModel.cachedFormData {
            self.selectedGroupId = cache.groupId
            self.activityDate = cache.date
            self.activityTitle = cache.title
            self.durationC = cache.durationC
            self.durationA = cache.durationA
            self.durationS = cache.durationS
            self.activityDescription = cache.description
        } else if let firstGroup = availableGroups.first {
            // Default first option if no cache
            self.selectedGroupId = firstGroup.C_GroupsID
        }

        // Set up publishers to monitor form changes
        setupPublishers()

        // Clear Cache when Receiving Notification
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ClearCachedFormData"),
            object: nil,
            queue: .main) { [weak self] _ in
                // Clear the cached form data
                Self.cachedFormData = nil
            }
    }

    private func setupPublishers() {
        // Combine all form field publishers to update cache on any change
        Publishers.CombineLatest4($selectedGroupId, $activityDate, $activityTitle,
                                  Publishers.CombineLatest3($durationC, $durationA, $durationS))
        .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.cacheFormData()
        }
        .store(in: &cancellables)

        $activityDescription
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.cacheFormData()
            }
            .store(in: &cancellables)
    }

    func validateDuration() {
        if totalDuration > 10 {
            errorMessage = "Total CAS duration cannot exceed 10 hours."
            durationC = 0
            durationA = 0
            durationS = 0
        } else {
            errorMessage = nil
        }
    }

    // Cache current form data automatically
    func cacheFormData() {
        // Only cache if there's meaningful data
        if !activityTitle.isEmpty || !activityDescription.isEmpty || totalDuration > 0 {
            AddRecordViewModel.cachedFormData = FormCache(
                groupId: selectedGroupId,
                date: activityDate,
                title: activityTitle,
                durationC: durationC,
                durationA: durationA,
                durationS: durationS,
                description: activityDescription
            )
        }
    }

    // Clear the cache after successful submission
    func clearCache() {
        AddRecordViewModel.cachedFormData = nil
    }

    func saveRecord() {
        guard !selectedGroupId.isEmpty,
              !activityTitle.isEmpty,
              !activityDescription.isEmpty,
              descriptionWordCount >= 80,  // Changed from character count to word count
              totalDuration > 0 else {
            errorMessage = "All fields are required."
            return
        }

        guard let sessionId = sessionService.sessionId else {
            errorMessage = "Wow, you have flexible fingers 😉"
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let activityDateString = dateFormatter.string(from: activityDate)

        let parameters = [
            "groupid": selectedGroupId,
            "studentid": loggedInStudentId,
            "actdate": activityDateString,
            "acttitle": activityTitle,
            "durationC": String(durationC),
            "durationA": String(durationA),
            "durationS": String(durationS),
            "actdesc": activityDescription,
            "groupy": "0",
            "joiny": "0"
        ]

        NetworkService.shared.request(
            endpoint: "cas_save_record.php",
            parameters: parameters,
            sessionId: sessionId
        ) { [weak self] (result: Result<[String: String], NetworkError>) in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                if response["status"] == "ok" {
                    self.clearCache() // Clear cache only on successful submission
                    self.onSave()
                } else {
                    self.errorMessage = response["status"] ?? "Unknown error occurred"
                    // Cache is automatically maintained
                }
            case .failure(let error):
                self.errorMessage = "Unable to save record: \(error.localizedDescription)"
                // Cache is automatically maintained
            }
        }
    }
}
