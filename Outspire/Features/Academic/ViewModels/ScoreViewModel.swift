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
    
    private let sessionService = SessionService.shared
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    init() {
        loadCachedData()
    }
    
    private func loadCachedData() {
        if let cachedTermsData = UserDefaults.standard.data(forKey: "cachedTerms"),
           let decodedTerms = try? JSONDecoder().decode([Term].self, from: cachedTermsData) {
            self.terms = decodedTerms
            
            if let savedTermId = UserDefaults.standard.string(forKey: "selectedTermId") {
                self.selectedTermId = savedTermId
                loadCachedScores(for: savedTermId)
            } else if let firstTerm = decodedTerms.first {
                self.selectedTermId = firstTerm.W_YearID
            }
        }
    }
    
    private func loadCachedScores(for termId: String) {
        if let cachedData = UserDefaults.standard.data(forKey: "cachedScores-\(termId)"),
           let decodedScores = try? JSONDecoder().decode([Score].self, from: cachedData) {
            self.scores = decodedScores
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
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "scoresCacheTimestamp-\(termId)")
        }
    }
    
    private func isCacheValid(for key: String) -> Bool {
        let lastUpdate = UserDefaults.standard.double(forKey: key)
        let currentTime = Date().timeIntervalSince1970
        return (currentTime - lastUpdate) < cacheDuration
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authentication required for requesting sensitive information."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.isUnlocked = true
                        self?.fetchTerms()
                    } else {
                        self?.isUnlocked = false
                        if let authError = authenticationError {
                            self?.errorMessage = "Authentication failed: \(authError.localizedDescription)"
                        }
                    }
                }
            }
        } else {
            // No biometrics available, could implement alternative authentication
            isUnlocked = true
            fetchTerms()
        }
    }
    
    func fetchTerms(forceRefresh: Bool = false) {
        if (!forceRefresh && !terms.isEmpty && isCacheValid(for: "termsCacheTimestamp")) {
            if selectedTermId.isEmpty, let firstTerm = terms.first {
                selectedTermId = firstTerm.W_YearID
            }
            fetchScores()
            return
        }
        
        isLoadingTerms = true
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
                    
                    if self.selectedTermId.isEmpty, let firstTerm = terms.first {
                        self.selectedTermId = firstTerm.W_YearID
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
        
        // Check if we have valid cache for THIS specific term
        if !forceRefresh && isCacheValid(for: "scoresCacheTimestamp-\(selectedTermId)") {
            loadCachedScores(for: selectedTermId)
            return
        }
        
        isLoading = true
        errorMessage = nil
        UserDefaults.standard.set(selectedTermId, forKey: "selectedTermId")
        
        let parameters = ["yearID": selectedTermId]
        
        NetworkService.shared.request(
            endpoint: "search_student_score.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[Score], NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let scores):
                    withAnimation {
                        self.scores = scores
                        self.cacheScores(for: self.selectedTermId, scores: scores)
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load scores: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func refreshData() {
        fetchTerms(forceRefresh: true)
    }
}
