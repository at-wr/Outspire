import SwiftUI

/// ClasstableViewModel with Enhanced Caching System
///
/// This view model provides comprehensive caching for academic timetable data to improve
/// app performance and reduce loading times, especially on the first screen (TodayView).
///
/// Key Features:
/// - 1-day cache duration for both years and timetable data
/// - Automatic cache validation with timestamp checking
/// - Background cache loading for instant UI updates
/// - Smart cache invalidation and refresh mechanisms
/// - Widget data sharing integration
///
/// Cache Strategy:
/// - Years data is cached for 24 hours (86400 seconds)
/// - Timetable data is cached per year ID for 24 hours
/// - Cache is automatically loaded on initialization
/// - Cache validation prevents unnecessary network requests
/// - Manual refresh capability with force refresh option
///
/// Performance Benefits:
/// - Reduces first screen loading time significantly
/// - Minimizes network requests for frequently accessed data
/// - Provides offline-like experience with cached data
/// - Smooth user experience with background updates
class ClasstableViewModel: ObservableObject {
    @Published var years: [Year] = []
    @Published var selectedYearId: String = ""
    @Published var timetable: [[String]] = [] {
        didSet {
            shareTimetableWithWidgets()
        }
    }
    @Published var errorMessage: String?
    @Published var isLoadingYears: Bool = false
    @Published var isLoadingTimetable: Bool = false
    @Published var lastUpdateTime: Date = Date()
    @Published var formattedLastUpdateTime: String = ""

    private let sessionService = SessionService.shared
    private let cacheDuration: TimeInterval = 86400  // 1 day in seconds

    init() {
        // Clean up outdated cache entries on initialization
        CacheManager.cleanupOutdatedCache()
        loadCachedData()
        updateFormattedTimestamp()
    }

    private func updateFormattedTimestamp() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        self.formattedLastUpdateTime = "Last updated: \(formatter.string(from: lastUpdateTime))"
    }

    private func loadCachedData() {
        // Load cached years
        if let cachedYearsData = UserDefaults.standard.data(forKey: "cachedYears"),
            let decodedYears = try? JSONDecoder().decode([Year].self, from: cachedYearsData),
            isCacheValid(for: "yearsCacheTimestamp")
        {
            self.years = decodedYears

            // Load the selected year ID
            if let savedYearId = UserDefaults.standard.string(forKey: "selectedYearId"),
                decodedYears.contains(where: { $0.W_YearID == savedYearId })
            {
                self.selectedYearId = savedYearId
            } else if let firstYear = decodedYears.first {
                self.selectedYearId = firstYear.W_YearID
            }

            // Load cached timetable for the selected year
            loadCachedTimetable(for: selectedYearId)
        }
    }

    private func loadCachedTimetable(for yearId: String) {
        guard !yearId.isEmpty else { return }

        let cacheKey = "cachedTimetable-\(yearId)"
        let timestampKey = "timetableCacheTimestamp-\(yearId)"

        if let cachedTimetableData = UserDefaults.standard.data(forKey: cacheKey),
            let decodedTimetable = try? JSONDecoder().decode(
                [[String]].self, from: cachedTimetableData),
            isCacheValid(for: timestampKey)
        {
            self.timetable = decodedTimetable

            // Load cached timestamp
            if let cachedTimestamp = UserDefaults.standard.object(forKey: timestampKey)
                as? TimeInterval
            {
                self.lastUpdateTime = Date(timeIntervalSince1970: cachedTimestamp)
            }

            updateFormattedTimestamp()
        }
    }

    private func cacheYears(_ years: [Year]) {
        if let encodedData = try? JSONEncoder().encode(years) {
            UserDefaults.standard.set(encodedData, forKey: "cachedYears")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "yearsCacheTimestamp")
        }
    }

    private func cacheTimetable(_ timetable: [[String]], for yearId: String) {
        let cacheKey = "cachedTimetable-\(yearId)"
        let timestampKey = "timetableCacheTimestamp-\(yearId)"

        if let encodedData = try? JSONEncoder().encode(timetable) {
            UserDefaults.standard.set(encodedData, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: timestampKey)
            self.lastUpdateTime = Date()
            updateFormattedTimestamp()
        }
    }

    private func isCacheValid(for key: String) -> Bool {
        let lastUpdate = UserDefaults.standard.double(forKey: key)
        let currentTime = Date().timeIntervalSince1970
        return (currentTime - lastUpdate) < cacheDuration
    }

    func fetchYears(forceRefresh: Bool = false) {
        // Check if we should use cached data
        if !forceRefresh && !years.isEmpty && isCacheValid(for: "yearsCacheTimestamp") {
            // Use cached data, but still fetch timetable if needed
            if timetable.isEmpty && !selectedYearId.isEmpty {
                fetchTimetable(forceRefresh: forceRefresh)
            }
            return
        }

        isLoadingYears = true
        errorMessage = nil

        NetworkService.shared.request(
            endpoint: "init_year_dropdown.php",
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[Year], NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoadingYears = false

                switch result {
                case .success(let years):
                    self.years = years
                    self.cacheYears(years)

                    // Select the most recent year (usually the first one)
                    if let firstYear = years.first {
                        self.selectedYearId = firstYear.W_YearID
                        UserDefaults.standard.set(firstYear.W_YearID, forKey: "selectedYearId")
                        self.fetchTimetable(forceRefresh: forceRefresh)
                    }

                case .failure(let error):
                    self.errorMessage = "Failed to load years: \(error.localizedDescription)"
                }
            }
        }
    }

    func fetchTimetable(forceRefresh: Bool = false) {
        guard !selectedYearId.isEmpty else {
            errorMessage = "Please select a year."
            return
        }

        // Check if we should use cached data
        let timestampKey = "timetableCacheTimestamp-\(selectedYearId)"
        if !forceRefresh && !timetable.isEmpty && isCacheValid(for: timestampKey) {
            return
        }

        isLoadingTimetable = true
        errorMessage = nil

        let parameters = [
            "timetableType": "teachertb",
            "yearID": selectedYearId,
        ]

        NetworkService.shared.request(
            endpoint: "school_student_timetable.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[[String]], NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoadingTimetable = false

                switch result {
                case .success(var timetable):
                    // Ensure the header row is properly formatted
                    if !timetable.isEmpty {
                        timetable[0] = ["", "Mon", "Tue", "Wed", "Thu", "Fri"]
                    }

                    self.timetable = timetable
                    self.cacheTimetable(timetable, for: self.selectedYearId)

                case .failure(let error):
                    self.errorMessage = "Failed to load timetable: \(error.localizedDescription)"
                }
            }
        }
    }

    func refreshData() {
        // Clear error message
        errorMessage = nil

        // Update timestamp immediately for visual feedback
        lastUpdateTime = Date()
        updateFormattedTimestamp()

        // Force refresh both years and timetable
        fetchYears(forceRefresh: true)
    }

    func selectYear(_ yearId: String) {
        guard yearId != selectedYearId else { return }

        selectedYearId = yearId
        UserDefaults.standard.set(yearId, forKey: "selectedYearId")

        // Load cached timetable for the new year if available
        loadCachedTimetable(for: yearId)

        // If no cached data or cache is invalid, fetch new data
        let timestampKey = "timetableCacheTimestamp-\(yearId)"
        if timetable.isEmpty || !isCacheValid(for: timestampKey) {
            fetchTimetable()
        }
    }

    private func shareTimetableWithWidgets() {
        if !timetable.isEmpty {
            NotificationCenter.default.post(
                name: .timetableDataDidChange,
                object: nil,
                userInfo: ["timetable": timetable]
            )

            if let encoded = try? JSONEncoder().encode(timetable) {
                UserDefaults(suiteName: "group.dev.wrye.Outspire")?.set(
                    encoded, forKey: "widgetTimetableData")
            }
        }
    }

    // MARK: - Cache Management

    func clearCache() {
        // Clear years cache
        UserDefaults.standard.removeObject(forKey: "cachedYears")
        UserDefaults.standard.removeObject(forKey: "yearsCacheTimestamp")

        // Clear all timetable caches
        for year in years {
            let cacheKey = "cachedTimetable-\(year.W_YearID)"
            let timestampKey = "timetableCacheTimestamp-\(year.W_YearID)"
            UserDefaults.standard.removeObject(forKey: cacheKey)
            UserDefaults.standard.removeObject(forKey: timestampKey)
        }

        // Clear selected year
        UserDefaults.standard.removeObject(forKey: "selectedYearId")

        // Reset view model state
        years = []
        timetable = []
        selectedYearId = ""
        errorMessage = nil
    }

    func getCacheStatus() -> (hasValidYearsCache: Bool, hasValidTimetableCache: Bool) {
        let hasValidYearsCache = !years.isEmpty && isCacheValid(for: "yearsCacheTimestamp")
        let hasValidTimetableCache =
            !timetable.isEmpty && !selectedYearId.isEmpty
            && isCacheValid(for: "timetableCacheTimestamp-\(selectedYearId)")

        return (hasValidYearsCache, hasValidTimetableCache)
    }
}
