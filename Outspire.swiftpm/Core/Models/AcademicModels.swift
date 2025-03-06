import Foundation

struct Year: Decodable, Identifiable {
    let W_YearID: String
    let W_Year: String
    
    var id: String { W_YearID }
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