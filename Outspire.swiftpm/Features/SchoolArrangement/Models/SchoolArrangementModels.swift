import Foundation

struct SchoolArrangementItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let publishDate: String
    let url: String
    var weekNumbers: [Int]
    var isExpanded: Bool = false
    
    static func == (lhs: SchoolArrangementItem, rhs: SchoolArrangementItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SchoolArrangementPage: Codable {
    let items: [SchoolArrangementItem]
    let totalPages: Int
    let currentPage: Int
}

struct SchoolArrangementDetail: Codable, Equatable {
    let id: String
    let title: String
    let publishDate: String
    let imageUrls: [String]
    let content: String
    
    static func == (lhs: SchoolArrangementDetail, rhs: SchoolArrangementDetail) -> Bool {
        return lhs.id == rhs.id
    }
}
