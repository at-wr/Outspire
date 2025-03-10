import SwiftUI
import SwiftSoup
import Combine

class SchoolArrangementViewModel: ObservableObject {
    @Published var arrangements: [SchoolArrangementItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var selectedDetail: SchoolArrangementDetail?
    @Published var isLoadingDetail: Bool = false
    @Published var refreshing: Bool = false
    
    private let baseURL = "https://www.wflms.cn"
    private let cacheKey = "cachedSchoolArrangements"
    private let detailCacheKeyPrefix = "cachedSchoolArrangementDetail-"
    private let cacheDuration: TimeInterval = 3600 // 1 hour
    
    init() {
        loadCachedData()
    }
    
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedPage = try? JSONDecoder().decode(SchoolArrangementPage.self, from: data),
           isCacheValid(for: cacheKey) {
            self.arrangements = cachedPage.items
            self.totalPages = cachedPage.totalPages
            self.currentPage = cachedPage.currentPage
        } else {
            // No valid cache, fetch fresh data
            fetchArrangements()
        }
    }
    
    private func isCacheValid(for key: String) -> Bool {
        let lastUpdate = UserDefaults.standard.double(forKey: "\(key)-timestamp")
        let currentTime = Date().timeIntervalSince1970
        return (currentTime - lastUpdate) < cacheDuration
    }
    
    func fetchArrangements(page: Int = 1) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let urlString = "\(baseURL)/site/site1/list/103ca_list_data_\(page).html"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.refreshing = false
                
                if let error = error {
                    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                    self.errorMessage = "Failed to decode response"
                    return
                }
                
                do {
                    let items = try self.parseArrangementListHTML(htmlString)
                    
                    // Parse total pages from the HTML
                    if let totalPages = try? self.parseTotalPages(htmlString) {
                        self.totalPages = totalPages
                    }
                    
                    if page == 1 {
                        self.arrangements = items
                    } else {
                        self.arrangements.append(contentsOf: items)
                    }
                    
                    self.currentPage = page
                    
                    // Cache the data
                    let pageData = SchoolArrangementPage(
                        items: self.arrangements,
                        totalPages: self.totalPages,
                        currentPage: self.currentPage
                    )
                    
                    if let encodedData = try? JSONEncoder().encode(pageData) {
                        UserDefaults.standard.set(encodedData, forKey: self.cacheKey)
                        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "\(self.cacheKey)-timestamp")
                    }
                    
                } catch {
                    self.errorMessage = "Failed to parse HTML: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchNextPage() {
        if currentPage < totalPages {
            fetchArrangements(page: currentPage + 1)
        }
    }
    
    func refreshData() {
        refreshing = true
        fetchArrangements(page: 1)
    }
    
    func fetchArrangementDetail(for item: SchoolArrangementItem) {
        // First check cache
        if let detail = getCachedDetail(id: item.id) {
            self.selectedDetail = detail
            return
        }
        
        guard !isLoadingDetail else { return }
        
        isLoadingDetail = true
        errorMessage = nil
        
        let urlString = "\(baseURL)\(item.url)"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid detail URL"
            self.isLoadingDetail = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingDetail = false
                
                if let error = error {
                    self.errorMessage = "Failed to load detail: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                    self.errorMessage = "Failed to decode detail response"
                    return
                }
                
                do {
                    let detail = try self.parseArrangementDetailHTML(htmlString, id: item.id, title: item.title, publishDate: item.publishDate)
                    self.selectedDetail = detail
                    
                    // Cache the detail
                    self.cacheDetail(detail)
                    
                } catch {
                    self.errorMessage = "Failed to parse detail HTML: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func parseArrangementListHTML(_ html: String) throws -> [SchoolArrangementItem] {
        let doc: Document = try SwiftSoup.parse(html)
        let listItems = try doc.select("ul li")
        
        return try listItems.compactMap { element -> SchoolArrangementItem? in
            guard let anchor = try? element.select("a").first() else { return nil }
            
            let url = try anchor.attr("href")
            let titleElement = try anchor.select(".list_categoryName").first()
            let title = try titleElement?.text() ?? "Unknown"
            let publishDateElement = try anchor.select(".publishTime").first()
            let publishDate = try publishDateElement?.text() ?? "Unknown Date"
            
            // Extract ID from URL
            let components = url.components(separatedBy: "_")
            let id = components.last?.components(separatedBy: ".").first ?? UUID().uuidString
            
            // Extract week numbers using regex
            let weekNumbers = extractWeekNumbers(from: title)
            
            return SchoolArrangementItem(
                id: id, 
                title: title, 
                publishDate: publishDate, 
                url: url,
                weekNumbers: weekNumbers
            )
        }
    }
    
    private func parseTotalPages(_ html: String) throws -> Int {
        let doc: Document = try SwiftSoup.parse(html)
        
        // Try to extract from the JavaScript function
        if let scriptText = try doc.select("script").filter({ try $0.html().contains("var pageNumber =") }).first() {
            let scriptContent = try scriptText.html()
            if let rangeStart = scriptContent.range(of: "var pageNumber = ('"),
               let rangeEnd = scriptContent.range(of: "'.replace", range: rangeStart.upperBound..<scriptContent.endIndex) {
                let numberString = scriptContent[rangeStart.upperBound..<rangeEnd.lowerBound]
                    .trimmingCharacters(in: CharacterSet(charactersIn: "'\";()"))
                if let totalPages = Int(numberString) {
                    return totalPages
                }
            }
        }
        
        return 1 // Default to 1 page if we can't parse it
    }
    
    private func parseArrangementDetailHTML(_ html: String, id: String, title: String, publishDate: String) throws -> SchoolArrangementDetail {
        let doc: Document = try SwiftSoup.parse(html)
        
        // Extract content from the detailBox5 div
        let contentDiv = try doc.select(".detailBox5").first()
        let content = try contentDiv?.html() ?? ""
        
        // Extract image URLs
        var imageUrls: [String] = []
        let images = try doc.select("img.uploadimages")
        
        for img in images {
            if try img.attr("src").contains("/oss/") && !img.attr("src").contains(".gif") {
                let imgSrc = try img.attr("src")
                let fullUrl = "\(baseURL)\(imgSrc)"
                imageUrls.append(fullUrl)
            }
        }
        
        return SchoolArrangementDetail(
            id: id,
            title: title,
            publishDate: publishDate,
            imageUrls: imageUrls,
            content: content
        )
    }
    
    private func extractWeekNumbers(from title: String) -> [Int] {
        let pattern = "【(.*?)】"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let range = NSRange(title.startIndex..<title.endIndex, in: title)
        guard let match = regex.firstMatch(in: title, range: range) else {
            return []
        }
        
        // Extract text inside brackets
        if let matchRange = Range(match.range(at: 1), in: title) {
            let weekText = String(title[matchRange])
            
            // Split by comma, 、, and spaces
            let components = weekText.components(separatedBy: CharacterSet(charactersIn: ",、 "))
            
            // Process each component to extract numbers
            var weekNumbers: [Int] = []
            for component in components {
                // Check for range (e.g., "1-3" or "4、5")
                if component.contains("-") {
                    let rangeComponents = component.components(separatedBy: "-")
                    if rangeComponents.count == 2,
                       let start = Int(rangeComponents[0]),
                       let end = Int(rangeComponents[1]) {
                        weekNumbers.append(contentsOf: start...end)
                    }
                } else if let number = Int(component) {
                    weekNumbers.append(number)
                }
            }
            
            return weekNumbers.sorted()
        }
        
        return []
    }
    
    // Detail caching methods
    private func cacheDetail(_ detail: SchoolArrangementDetail) {
        if let encodedData = try? JSONEncoder().encode(detail) {
            let key = detailCacheKeyPrefix + detail.id
            UserDefaults.standard.set(encodedData, forKey: key)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "\(key)-timestamp")
        }
    }
    
    private func getCachedDetail(id: String) -> SchoolArrangementDetail? {
        let key = detailCacheKeyPrefix + id
        
        guard let data = UserDefaults.standard.data(forKey: key),
              let cachedDetail = try? JSONDecoder().decode(SchoolArrangementDetail.self, from: data),
              isCacheValid(for: key) else {
            return nil
        }
        
        return cachedDetail
    }
    
    func toggleExpand(item: SchoolArrangementItem) {
        if let index = arrangements.firstIndex(where: { $0.id == item.id }) {
            arrangements[index].isExpanded.toggle()
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: "\(cacheKey)-timestamp")
        
        // Clear all detail caches
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.hasPrefix(detailCacheKeyPrefix) {
                UserDefaults.standard.removeObject(forKey: key)
                UserDefaults.standard.removeObject(forKey: "\(key)-timestamp")
            }
        }
    }
}
