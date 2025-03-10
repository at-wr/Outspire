import Foundation

struct SchoolArrangementItem: Identifiable, Equatable {
    let id: String
    let title: String
    let publishDate: String
    let url: String
    let weekNumbers: [Int]
    var isExpanded: Bool = false
    
    static func == (lhs: SchoolArrangementItem, rhs: SchoolArrangementItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SchoolArrangementDetail: Identifiable, Equatable {
    let id: String
    let title: String
    let publishDate: String
    let imageUrls: [String]
    let content: String
    
    static func == (lhs: SchoolArrangementDetail, rhs: SchoolArrangementDetail) -> Bool {
        return lhs.id == rhs.id
    }
}

// Helper struct for grouping arrangements
struct ArrangementGroup: Identifiable {
    let id: String
    let title: String
    var items: [SchoolArrangementItem]  // Change from let to var
    var isExpanded: Bool = true
}

// Cache manager for image caching
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, NSData>()
    
    func setImage(data: Data, for url: String) {
        cache.setObject(data as NSData, forKey: url as NSString)
    }
    
    func getImage(for url: String) -> Data? {
        return cache.object(forKey: url as NSString) as Data?
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
