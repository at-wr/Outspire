import SwiftUI
import SwiftSoup
import Combine

class SchoolArrangementViewModel: ObservableObject {
    @Published var arrangements: [SchoolArrangementItem] = []
    @Published var arrangementGroups: [ArrangementGroup] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var selectedDetail: SchoolArrangementDetail?
    @Published var isLoadingDetail: Bool = false
    
    private let baseURL = "https://www.wflms.cn"
    private var currentTask: URLSessionDataTask?
    private var detailTask: URLSessionDataTask?
    private var processedImageUrls = Set<String>()
    
    init() {
        fetchArrangements()
    }
    
    deinit {
        cancelAllTasks()
    }
    
    // MARK: - Public Methods
    
    func fetchArrangements(page: Int = 1) {
        guard !isLoading else { return }
        
        // Cancel any existing task
        currentTask?.cancel()
        
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
        request.timeoutInterval = 15
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error as NSError?, error.code != NSURLErrorCancelled {
                    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                    self.errorMessage = "Failed to decode response"
                    return
                }
                
                do {
                    let items = try self.parseArrangementListHTML(htmlString)
                    
                    if let totalPages = try? self.parseTotalPages(htmlString) {
                        self.totalPages = totalPages
                    }
                    
                    if page == 1 {
                        self.arrangements = items
                    } else {
                        self.arrangements.append(contentsOf: items)
                    }
                    
                    self.currentPage = page
                    self.updateArrangementGroups()
                } catch {
                    self.errorMessage = "Failed to parse HTML: \(error.localizedDescription)"
                }
            }
        }
        
        currentTask?.resume()
    }
    
    func fetchNextPage() {
        if currentPage < totalPages && !isLoading {
            fetchArrangements(page: currentPage + 1)
        }
    }
    
    func refreshData() {
        fetchArrangements(page: 1)
    }
    
    func fetchArrangementDetail(for item: SchoolArrangementItem) {
        guard !isLoadingDetail else { return }
        
        // Cancel any existing task
        detailTask?.cancel()
        
        isLoadingDetail = true
        errorMessage = nil
        selectedDetail = nil
        
        // Sanitize URL - handle cases where the URL might contain spaces or invalid characters
        let urlString = "\(baseURL)\(item.url)"
            .replacingOccurrences(of: " ", with: "%20")
        
        print("DEBUG: Fetching detail from \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("DEBUG: Invalid URL: \(urlString)")
            self.errorMessage = "Invalid detail URL"
            self.isLoadingDetail = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        detailTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingDetail = false
                
                if let error = error as NSError?, error.code != NSURLErrorCancelled {
                    print("DEBUG: Network error: \(error)")
                    self.errorMessage = "Failed to load detail: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                    print("DEBUG: Failed to decode response")
                    self.errorMessage = "Failed to decode response"
                    return
                }
                
                do {
                    // Reset processed URLs for each new detail
                    self.processedImageUrls.removeAll()
                    
                    let detail = try self.parseArrangementDetailHTML(htmlString, id: item.id, title: item.title, publishDate: item.publishDate)
                    
                    // IMPORTANT: We're not requiring images anymore
                    // Just create the detail object regardless
                    print("DEBUG: Detail parsed successfully with \(detail.imageUrls.count) images")
                    self.selectedDetail = detail
                    
                } catch {
                    print("DEBUG: Detail parsing error: \(error)")
                    self.errorMessage = "Failed to parse detail: \(error.localizedDescription)"
                }
            }
        }
        
        detailTask?.resume()
    }
    
    func toggleGroupExpansion(_ groupId: String) {
        if let index = arrangementGroups.firstIndex(where: { $0.id == groupId }) {
            arrangementGroups[index].isExpanded.toggle()
        }
    }
    
    func toggleItemExpansion(_ itemId: String) {
        if let groupIndex = arrangementGroups.firstIndex(where: { group in
            group.items.contains(where: { $0.id == itemId })
        }) {
            // Create a mutable copy of the items array
            var updatedItems = arrangementGroups[groupIndex].items
            
            // Find the item and toggle its expansion state
            if let itemIndex = updatedItems.firstIndex(where: { $0.id == itemId }) {
                // Create a new item with toggled isExpanded value
                var updatedItem = updatedItems[itemIndex]
                updatedItem.isExpanded.toggle()
                
                // Replace the item in the array
                updatedItems[itemIndex] = updatedItem
                
                // Create a new group with the updated items
                var updatedGroup = arrangementGroups[groupIndex]
                updatedGroup.items = updatedItems
                
                // Update the group in the array
                arrangementGroups[groupIndex] = updatedGroup
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateArrangementGroups() {
        // Group by month and year
        var groups: [String: [SchoolArrangementItem]] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for item in arrangements {
            let key: String
            if let date = dateFormatter.date(from: item.publishDate) {
                dateFormatter.dateFormat = "MMMM yyyy"
                key = dateFormatter.string(from: date)
            } else {
                key = "Unknown Date"
            }
            
            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(item)
        }
        
        // Sort items within each group
        for key in groups.keys {
            groups[key]?.sort { $0.publishDate > $1.publishDate }
        }
        
        // Create arrangement groups and sort them
        let sortedKeys = groups.keys.sorted { key1, key2 in
            if key1 == "Unknown Date" { return false }
            if key2 == "Unknown Date" { return true }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            
            if let date1 = dateFormatter.date(from: key1),
               let date2 = dateFormatter.date(from: key2) {
                return date1 > date2
            }
            return key1 > key2
        }
        
        // Create groups
        arrangementGroups = sortedKeys.compactMap { key in
            guard let items = groups[key] else { return nil }
            return ArrangementGroup(id: key, title: key, items: items)
        }
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
            
            // Extract week numbers
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
        if let scriptText = try doc.select("script").filter({ try $0.html().contains("var pageNumber =") }).first {
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
        print("DEBUG: Starting to parse HTML for \(title)")
        
        let content: String
        var imageUrls: [String] = []
        
        do {
            let doc: Document = try SwiftSoup.parse(html)
            
            // Try to get the content
            let contentDiv = try doc.select(".detailBox5").first()
            content = try contentDiv?.html() ?? ""
            print("DEBUG: Content extracted, length: \(content.count)")
            
            // Extract image URLs - try multiple approaches
            
            // 1. First try specific class
            let uploadImages = try doc.select("img.uploadimages")
            print("DEBUG: Found \(uploadImages.count) images with uploadimages class")
            
            for img in uploadImages {
                do {
                    let imgSrc = try img.attr("src")
                    if imgSrc.contains("/oss/") && !imgSrc.contains(".gif") {
                        let fullUrl = imgSrc.hasPrefix("http") ? imgSrc : "\(baseURL)\(imgSrc)"
                        print("DEBUG: Found image URL: \(fullUrl)")
                        
                        if !processedImageUrls.contains(fullUrl) {
                            imageUrls.append(fullUrl)
                            processedImageUrls.insert(fullUrl)
                        }
                    }
                } catch {
                    print("DEBUG: Error extracting src: \(error)")
                    continue
                }
            }
            
            // 2. Try all img tags with _src attribute (some sites use this)
            if imageUrls.isEmpty {
                let allImages = try doc.select("img")
                
                for img in allImages {
                    do {
                        // Try standard src first
                        let imgSrc = try img.attr("src")
                        if imgSrc.contains("/oss/") && !imgSrc.contains(".gif") {
                            let fullUrl = imgSrc.hasPrefix("http") ? imgSrc : "\(baseURL)\(imgSrc)"
                            
                            if !processedImageUrls.contains(fullUrl) {
                                imageUrls.append(fullUrl)
                                processedImageUrls.insert(fullUrl)
                                continue
                            }
                        }
                        
                        // Try _src attribute
                        if img.hasAttr("_src") {
                            let imgSrc = try img.attr("_src")
                            if imgSrc.contains("/oss/") && !imgSrc.contains(".gif") {
                                let fullUrl = imgSrc.hasPrefix("http") ? imgSrc : "\(baseURL)\(imgSrc)"
                                
                                if !processedImageUrls.contains(fullUrl) {
                                    imageUrls.append(fullUrl)
                                    processedImageUrls.insert(fullUrl)
                                }
                            }
                        }
                        
                        // Try fileid attribute which some sites use
                        if img.hasAttr("fileid") {
                            let fileId = try img.attr("fileid")
                            if !fileId.isEmpty {
                                let fullUrl = "\(baseURL)/oss/\(fileId)"
                                
                                if !processedImageUrls.contains(fullUrl) {
                                    imageUrls.append(fullUrl)
                                    processedImageUrls.insert(fullUrl)
                                }
                            }
                        }
                    } catch {
                        continue
                    }
                }
            }
            
            // Add more robust image finding
            if imageUrls.isEmpty {
                // Try another selector pattern - some sites structure differently
                let allDivs = try doc.select("div.detailBody")
                for div in allDivs {
                    let divImages = try div.select("img")
                    for img in divImages {
                        // Check for any reasonable image URL
                        do {
                            if let imgSrc = try? img.attr("src") {
                                if !imgSrc.isEmpty && (
                                    imgSrc.contains("/oss/") || 
                                    imgSrc.contains("/uploads/") || 
                                    imgSrc.lowercased().hasSuffix(".jpg") || 
                                    imgSrc.lowercased().hasSuffix(".png") || 
                                    imgSrc.lowercased().hasSuffix(".jpeg")
                                ) {
                                    let fullUrl = imgSrc.hasPrefix("http") ? imgSrc : "\(baseURL)\(imgSrc)"
                                    
                                    if !processedImageUrls.contains(fullUrl) {
                                        print("DEBUG: Found additional image URL: \(fullUrl)")
                                        imageUrls.append(fullUrl)
                                        processedImageUrls.insert(fullUrl)
                                    }
                                }
                            }
                        } catch {
                            continue
                        }
                    }
                }
            }
            
            print("DEBUG: Found a total of \(imageUrls.count) images")
            
            // Try to extract content from other common containers if primary selector failed
            if content.isEmpty {
                if let contentDiv = try? doc.select(".detailBody").first() {
                    content = try contentDiv.html()
                } else if let contentDiv = try? doc.select(".content").first() {
                    content = try contentDiv.html()
                } else if let contentDiv = try? doc.select(".article-content").first() {
                    content = try contentDiv.html()
                }
                print("DEBUG: Found alternative content, length: \(content.count)")
            }
            
        } catch {
            print("DEBUG: Critical HTML parsing error: \(error)")
            // Instead of failing, return an empty content
            content = ""
        }
        
        // Create detail even if no images found
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
                // Check for range (e.g., "1-3")
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
    
    private func cancelAllTasks() {
        currentTask?.cancel()
        currentTask = nil
        
        detailTask?.cancel()
        detailTask = nil
    }
    
    // Improved URL validation helper
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // Validate and sanitize a URL string
    private func sanitizeURL(_ urlString: String) -> String {
        return urlString
            .replacingOccurrences(of: " ", with: "%20")
            .replacingOccurrences(of: "\\", with: "/")
    }
}
