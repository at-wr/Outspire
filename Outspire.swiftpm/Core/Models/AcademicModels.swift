import Foundation

struct Year: Identifiable, Codable, Equatable {
    var id: String { W_YearID }
    let W_YearID: String
    let W_Year: String

    static func == (lhs: Year, rhs: Year) -> Bool {
        return lhs.W_YearID == rhs.W_YearID
    }
}

struct Score: Decodable, Identifiable {
    let id: String
    let courseName: String
    let grade: String
    let teacher: String
    let term: String
    
    // Placeholder until define the actual model
    // based on the API response structure
}