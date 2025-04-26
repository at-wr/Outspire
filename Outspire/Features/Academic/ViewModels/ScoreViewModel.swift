import SwiftUI
import LocalAuthentication

struct Term: Identifiable, Codable {
    let W_YearID: String
    let W_Year: String
    let W_Term: String

    var id: String { W_YearID }

    var displayName: String {
        return "\(W_Year) Term \(W_Term)"
    }
}

struct Score: Identifiable, Codable {
    let IB_SubjectID: String
    let IB_SubjectE: String
    let S_Name: String
    let Score1: String
    let LScore1: String
    let Score2: String
    let LScore2: String
    let Score3: String
    let LScore3: String
    let Score4: String
    let LScore4: String
    let Score5: String
    let LScore5: String

    var id: String { IB_SubjectID }

    var subjectName: String { IB_SubjectE }
    var examScores: [ExamScore] {
        [
            ExamScore(name: "Monthly 1", score: Score1, level: LScore1),
            ExamScore(name: "Mid-term", score: Score2, level: LScore2),
            ExamScore(name: "Monthly 2", score: Score3, level: LScore3),
            ExamScore(name: "Final-term", score: Score4, level: LScore4),
            ExamScore(name: "Homework", score: Score5, level: LScore5)
        ]
    }

    var averageScore: Double {
        let validScores = [Score1, Score2, Score3, Score4].compactMap { Double($0) }.filter { $0 > 0 }
        return validScores.isEmpty ? 0 : validScores.reduce(0, +) / Double(validScores.count)
    }

    var highestScore: String {
        let scores = [Score1, Score2, Score3, Score4]
        return scores.compactMap { Double($0) }.filter { $0 > 0 }.max().map { String($0) } ?? "N/A"
    }
}

struct ExamScore: Identifiable {
    let name: String
    let score: String
    let level: String

    var id: String { name }
    var hasScore: Bool { score != "0" && !score.isEmpty }
}

class ScoreViewModel: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var errorMessage: String?
    @Published var scores: [Score] = []
    @Published var isLoading: Bool = false
    @Published var terms: [Term] = []
    @Published var isLoadingTerms: Bool = false
    @Published var selectedTermId: String = ""
    @Published var lastUpdateTime: Date = Date()
    @Published var formattedLastUpdateTime: String = ""
    
    // Track terms with available data
    @Published var termsWithData: Set<String> = []
    
    private let sessionService = SessionService.shared
    private let cacheDuration: TimeInterval = 300

    init() {
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
        // Load cached terms with data
        if let cachedTermsWithData = UserDefaults.standard.array(forKey: "termsWithData") as? [String] {
            self.termsWithData = Set(cachedTermsWithData)
        }
        
        if let cachedTermsData = UserDefaults.standard.data(forKey: "cachedTerms"),
           let decodedTerms = try? JSONDecoder().decode([Term].self, from: cachedTermsData) {
            self.terms = decodedTerms
            
            // First try to use the previously selected term
            if let savedTermId = UserDefaults.standard.string(forKey: "selectedTermId"),
               termsWithData.contains(savedTermId) {
                self.selectedTermId = savedTermId
                loadCachedScores(for: savedTermId)
            } 
            // If no saved term or it has no data, find the most recent term with data
            else if let mostRecentTermWithData = findMostRecentTermWithData(from: decodedTerms) {
                self.selectedTermId = mostRecentTermWithData
                loadCachedScores(for: mostRecentTermWithData)
            }
            // If no terms with data yet, just select the most recent term
            else if let mostRecentTerm = findMostRecentTerm(from: decodedTerms) {
                self.selectedTermId = mostRecentTerm
            }
        }
    }
    
    private func findMostRecentTermWithData(from terms: [Term]) -> String? {
        // Sort terms by year and term number in descending order
        let sortedTerms = terms.sorted { 
            // First compare years
            if $0.W_Year != $1.W_Year {
                return $0.W_Year > $1.W_Year
            }
            // Then compare term numbers
            return $0.W_Term > $1.W_Term 
        }
        
        // Find the first term that has data
        return sortedTerms.first { termsWithData.contains($0.W_YearID) }?.W_YearID
    }
    
    private func findMostRecentTerm(from terms: [Term]) -> String? {
        // Sort terms by year and term number in descending order
        let sortedTerms = terms.sorted { 
            // First compare years
            if $0.W_Year != $1.W_Year {
                return $0.W_Year > $1.W_Year
            }
            // Then compare term numbers
            return $0.W_Term > $1.W_Term 
        }
        
        return sortedTerms.first?.W_YearID
    }

    private func loadCachedScores(for termId: String) {
        // Clear any previous error message when loading new scores
        self.errorMessage = nil
        
        if let cachedData = UserDefaults.standard.data(forKey: "cachedScores-\(termId)"),
           let decodedScores = try? JSONDecoder().decode([Score].self, from: cachedData) {
            self.scores = decodedScores
            
            // Load cached timestamp
            if let cachedTimestamp = UserDefaults.standard.object(forKey: "scoresCacheTimestamp-\(termId)") as? TimeInterval {
                self.lastUpdateTime = Date(timeIntervalSince1970: cachedTimestamp)
            } else {
                self.lastUpdateTime = Date()
            }
            
            // Update the formatted timestamp
            updateFormattedTimestamp()
            
            // Update termsWithData based on whether the cached scores are empty or not
            if !decodedScores.isEmpty {
                termsWithData.insert(termId)
            } else {
                termsWithData.remove(termId)
            }
            UserDefaults.standard.set(Array(termsWithData), forKey: "termsWithData")
        } else {
            // If we can't load cached scores, clear the current scores
            self.scores = []
            
            // Reset timestamp to current time
            self.lastUpdateTime = Date()
            updateFormattedTimestamp()
            
            // Also remove this term from termsWithData since we have no data for it
            termsWithData.remove(termId)
            UserDefaults.standard.set(Array(termsWithData), forKey: "termsWithData")
        }
    }

    private func cacheTerms(_ terms: [Term]) {
        if let encodedData = try? JSONEncoder().encode(terms) {
            UserDefaults.standard.set(encodedData, forKey: "cachedTerms")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "termsCacheTimestamp")
        }
    }

    private func cacheScores(for termId: String, scores: [Score]) {
        if let encodedData = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encodedData, forKey: "cachedScores-\(termId)")
            
            // Save current timestamp
            let currentTime = Date().timeIntervalSince1970
            UserDefaults.standard.set(currentTime, forKey: "scoresCacheTimestamp-\(termId)")
            self.lastUpdateTime = Date()
            
            // Update terms with data set
            if !scores.isEmpty {
                // If we got scores, add this term to the terms with data set
                termsWithData.insert(termId)
            } else {
                // If there are no scores, remove this term from the terms with data set
                termsWithData.remove(termId)
            }
            // Update the persisted set
            UserDefaults.standard.set(Array(termsWithData), forKey: "termsWithData")
        }
    }

    func isCacheValid(for key: String) -> Bool {
        let lastUpdate = UserDefaults.standard.double(forKey: key)
        let currentTime = Date().timeIntervalSince1970
        return (currentTime - lastUpdate) < cacheDuration
    }

    func authenticate() {
        let context = LAContext()
        context.localizedFallbackTitle = "Use device password"
        var error: NSError?

        // Set loading state first before authentication
        isLoading = true

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authentication required for requesting sensitive information."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, authenticationError in
                guard let self = self else { return }
                
                // Small delay before updating UI to ensure smooth transitions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isLoading = false
                    
                    if success {
                        self.isUnlocked = true
                        self.errorMessage = nil
                        // Add a small delay before fetching terms to ensure smooth animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.fetchTerms()
                        }
                    } else {
                        self.isUnlocked = false
                        if let authError = authenticationError {
                            self.errorMessage = "Authentication failed: \(authError.localizedDescription)"
                        }
                    }
                }
            }
        } else {
            // Small delay before updating UI to ensure smooth transitions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isLoading = false
                self.isUnlocked = false
                self.errorMessage = "Authentication is not available on this device."
            }
        }
    }

    func fetchTerms(forceRefresh: Bool = false) {
        if !forceRefresh && !terms.isEmpty && isCacheValid(for: "termsCacheTimestamp") {
            if selectedTermId.isEmpty {
                // Try to find the most recent term with data
                if let mostRecentTermWithData = findMostRecentTermWithData(from: terms) {
                    selectedTermId = mostRecentTermWithData
                    loadCachedScores(for: mostRecentTermWithData)
                } else if let mostRecentTerm = findMostRecentTerm(from: terms) {
                    selectedTermId = mostRecentTerm
                }
            }
            fetchScores()
            return
        }

        isLoadingTerms = true
        // Clear error message when starting to fetch
        errorMessage = nil

        NetworkService.shared.request(
            endpoint: "init_term_dropdown.php",
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[Term], NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoadingTerms = false

                switch result {
                case .success(let terms):
                    self.terms = terms
                    self.cacheTerms(terms)

                    // Always try to select the most recent term first, regardless of previous selection
                    if let mostRecentTerm = self.findMostRecentTerm(from: terms) {
                        self.selectedTermId = mostRecentTerm
                        
                        // If the most recent term has data, load it
                        if self.termsWithData.contains(mostRecentTerm) {
                            self.loadCachedScores(for: mostRecentTerm)
                        } else {
                            // If there's no data for the most recent term,
                            // try to find the most recent term that has data as a fallback
                            if let mostRecentTermWithData = self.findMostRecentTermWithData(from: terms) {
                                self.selectedTermId = mostRecentTermWithData
                                self.loadCachedScores(for: mostRecentTermWithData)
                            }
                        }
                    }
                    
                    self.fetchScores()

                case .failure(let error):
                    self.errorMessage = "Failed to load terms: \(error.localizedDescription)"
                }
            }
        }
    }

    func fetchScores(forceRefresh: Bool = false) {
        guard !selectedTermId.isEmpty else {
            errorMessage = "Please select a term."
            return
        }

        if !forceRefresh && isCacheValid(for: "scoresCacheTimestamp-\(selectedTermId)") {
            loadCachedScores(for: selectedTermId)
            return
        }

        // Set loading state first, before clearing scores
        isLoading = true
        
        // Small delay before clearing scores to minimize layout jumps
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Clear any error message from previous requests - this will be set again if the request fails
            self.errorMessage = nil
            // Clear scores while loading - do this after a short delay to prevent layout jumps
            self.scores = []
        }
        
        UserDefaults.standard.set(selectedTermId, forKey: "selectedTermId")

        let parameters = ["yearID": selectedTermId]

        // Using custom responseHandler to handle null responses properly
        fetchScoresWithNullHandling(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Small delay before updating UI to ensure smooth transitions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let scores):
                        withAnimation {
                            self.scores = scores
                            // Update the last update time when new scores are fetched
                            self.lastUpdateTime = Date()
                            self.updateFormattedTimestamp()
                            self.cacheScores(for: self.selectedTermId, scores: scores)
                            
                            // If scores are empty, show a contextual message based on term date
                            if scores.isEmpty {
                                self.determineEmptyScoreMessage(for: self.selectedTermId)
                            } else {
                                // Clear any error message if scores loaded successfully
                                self.errorMessage = nil
                            }
                        }
                    case .failure(let error):
                        // Show error message
                        self.errorMessage = "Failed to load scores: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    // Helper function to determine appropriate message for empty terms
    private func determineEmptyScoreMessage(for termId: String) {
        // Find the term object to get more context
        guard let term = terms.first(where: { $0.W_YearID == termId }) else {
            self.errorMessage = "No scores available for this term yet."
            return
        }
        
        // Current date for comparison
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        
        // Extract year from the term.W_Year (assuming it's in a format that includes the year)
        guard let termYear = Int(term.W_Year) else {
            self.errorMessage = "No scores available for this term yet."
            return
        }
        
        // Term number for sequence context
        let termNumber = Int(term.W_Term) ?? 0
        
        // Logic for different messages based on term timing
        if termYear > currentYear {
            // Future term
            self.errorMessage = "This term hasn't started yet."
        } else if termYear < currentYear - 3 {
            // Very old term - likely before student enrolled
            self.errorMessage = "This term occurred before your enrollment."
        } else if termYear == currentYear && termNumber > (calendar.component(.month, from: currentDate) / 4) + 1 {
            // Current year but future term
            self.errorMessage = "This term hasn't started yet."
        } else {
            // Current or recent term without data
            self.errorMessage = "No scores available for this term yet."
        }
    }
    
    // Special handler for the API endpoint that might return null
    private func fetchScoresWithNullHandling(parameters: [String: String], completion: @escaping (Result<[Score], NetworkError>) -> Void) {
        guard let url = URL(string: "\(Configuration.baseURL)/php/search_student_score.php") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var headers = ["Content-Type": "application/x-www-form-urlencoded"]
        if let sessionId = sessionService.sessionId {
            headers["Cookie"] = "PHPSESSID=\(sessionId)"
        }
        request.allHTTPHeaderFields = headers
        
        // URL-encode parameter values - use the same encoding as NetworkService
        let paramString = parameters.map { key, value -> String in
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(key)=\(encodedValue)"
        }.joined(separator: "&")
        
        request.httpBody = paramString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.requestFailed(error)))
                }
                return
            }
            
            // Check HTTP response for server errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                DispatchQueue.main.async {
                    completion(.failure(.serverError(httpResponse.statusCode)))
                }
                return
            }
            
            guard let data = data, !data.isEmpty else {
                DispatchQueue.main.async {
                    completion(.success([]))  // Empty array for no data
                }
                return
            }
            
            // Check if the response is "null"
            if let string = String(data: data, encoding: .utf8), 
               string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "null" {
                DispatchQueue.main.async {
                    completion(.success([]))  // Empty array for null response
                }
                return
            }
            
            // Normal JSON decoding for valid data
            do {
                let decodedResponse = try JSONDecoder().decode([Score].self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedResponse))
                }
            } catch {
                print("Score decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
                
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    func refreshData() {
        // Clear any error message
        errorMessage = nil
        
        // Update the last update time immediately to give visual feedback
        lastUpdateTime = Date()
        updateFormattedTimestamp()
        
        // Force refresh data by fetching terms first
        fetchTerms(forceRefresh: true)
    }
    
    // Method to explicitly select the most recent term
    func selectMostRecentTerm() {
        if let mostRecentTerm = findMostRecentTerm(from: terms) {
            // Only change if we're not already on the most recent term
            if selectedTermId != mostRecentTerm {
                selectedTermId = mostRecentTerm
                fetchScores()
            }
        }
    }
}
