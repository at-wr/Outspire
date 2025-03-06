import SwiftUI

class ClasstableViewModel: ObservableObject {
    @Published var years: [Year] = []
    @Published var selectedYearId: String = ""
    @Published var timetable: [[String]] = []
    @Published var errorMessage: String?
    @Published var isLoadingYears: Bool = false
    @Published var isLoadingTimetable: Bool = false
    
    private let sessionService = SessionService.shared
    
    func fetchYears() {
        isLoadingYears = true
        errorMessage = nil
        
        NetworkService.shared.request(
            endpoint: "init_year_dropdown.php",
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[Year], NetworkError>) in
            guard let self = self else { return }
            self.isLoadingYears = false
            
            switch result {
            case .success(let years):
                self.years = years
                if let firstYear = self.years.first {
                    self.selectedYearId = firstYear.W_YearID
                    self.fetchTimetable()
                }
            case .failure(let error):
                self.errorMessage = "Failed to load years: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchTimetable() {
        guard !selectedYearId.isEmpty else {
            errorMessage = "Please select a year."
            return
        }
        
        isLoadingTimetable = true
        errorMessage = nil
        
        let parameters = [
            "timetableType": "teachertb",
            "yearID": selectedYearId
        ]
        
        NetworkService.shared.request(
            endpoint: "school_student_timetable.php",
            parameters: parameters,
            sessionId: sessionService.sessionId
        ) { [weak self] (result: Result<[[String]], NetworkError>) in
            guard let self = self else { return }
            self.isLoadingTimetable = false
            
            switch result {
            case .success(var timetable):
                timetable[0] = ["", "Mon", "Tue", "Wed", "Thu", "Fri"]
                self.timetable = timetable
            case .failure(let error):
                self.errorMessage = "Failed to load timetable: \(error.localizedDescription)"
            }
        }
    }
}
