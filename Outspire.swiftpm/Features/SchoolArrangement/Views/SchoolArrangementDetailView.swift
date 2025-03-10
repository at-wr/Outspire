import SwiftUI

struct SchoolArrangementDetailView: View {
    let detail: SchoolArrangementDetail
    @State private var animateContent = false
    @State private var showFullScreenImage = false
    @State private var selectedImageURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title section
                VStack(alignment: .leading, spacing: 8) {
                    Text(detail.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(detail.publishDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: animateContent)
                
                // Images section
                if !detail.imageUrls.isEmpty {
                    Text("Attachments")
                        .font(.headline)
                        .padding(.bottom, 4)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateContent)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(detail.imageUrls.enumerated()), id: \.element) { index, imageUrlString in
                                if let imageUrl = URL(string: imageUrlString) {
                                    SafeImageView(url: imageUrl)
                                        .frame(height: 200)
                                        .frame(width: 280)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .contentShape(Rectangle())
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                        .onTapGesture {
                                            selectedImageURL = imageUrl
                                            showFullScreenImage = true
                                        }
                                        .opacity(animateContent ? 1 : 0)
                                        .offset(y: animateContent ? 0 : 15)
                                        .animation(.easeOut(duration: 0.5).delay(0.3 + Double(index) * 0.1), value: animateContent)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Content section
                if !detail.content.isEmpty {
                    Divider()
                        .padding(.vertical, 8)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: animateContent)
                    
                    Text("Description")
                        .font(.headline)
                        .padding(.bottom, 4)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: animateContent)
                    
                    HTMLContentView(htmlContent: detail.content)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.6), value: animateContent)
                }
            }
            .padding()
        }
        .navigationTitle("School Arrangement")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showFullScreenImage) {
            if let imageURL = selectedImageURL {
                ArrangementImagePreview(imageURL: imageURL, title: detail.title, date: detail.publishDate)
            }
        }
        .onAppear {
            // Animate content when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateContent = true
            }
        }
    }
}

// Improved SafeImageView with better error handling and caching
struct SafeImageView: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .frame(width: 280)
                        .shimmering()
                }
            } else if loadFailed {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Failed to load")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.tertiarySystemBackground))
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        // Check image cache first
        if let cachedImage = ImageCache.shared.get(url: url.absoluteString) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        isLoading = true
        loadFailed = false
        
        var request = URLRequest(url: url)
        request.addValue("https://www.wflms.cn", forHTTPHeaderField: "Referer")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let loadedImage = UIImage(data: data) {
                    self.image = loadedImage
                    // Cache the loaded image
                    ImageCache.shared.set(image: loadedImage, for: url.absoluteString)
                } else {
                    loadFailed = true
                }
            }
        }.resume()
    }
}

// Simple preview for arrangement images
struct ArrangementImagePreview: View {
    let imageURL: URL
    let title: String
    let date: String
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var scale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @GestureState private var dragOffset = CGSize.zero
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header info
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                        
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                
                // Image content
                ZStack {
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle())
                    } else if loadFailed {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                            Text("Image failed to load")
                                .foregroundStyle(.secondary)
                        }
                    } else if let image = image {
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale)
                                .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .gesture(
                                    DragGesture()
                                        .updating($dragOffset) { value, state, _ in
                                            if scale > 1 {
                                                state = value.translation
                                            }
                                        }
                                        .onEnded { value in
                                            if scale > 1 {
                                                offset.width += value.translation.width
                                                offset.height += value.translation.height
                                            }
                                        }
                                )
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = min(max(1, scale * value / 1.0), 4.0)
                                        }
                                )
                                .gesture(
                                    TapGesture(count: 2)
                                        .onEnded {
                                            withAnimation(.spring()) {
                                                if scale > 1 {
                                                    scale = 1.0
                                                    offset = .zero
                                                } else {
                                                    scale = 2.0
                                                }
                                            }
                                        }
                                )
                        }
                    }
                }
                .clipped()
                .contentShape(Rectangle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let _ = image, scale != 1.0 || offset != .zero {
                        Button {
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        // Check cache first
        if let cachedImage = ImageCache.shared.get(url: imageURL.absoluteString) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        isLoading = true
        loadFailed = false
        
        var request = URLRequest(url: imageURL)
        request.addValue("https://www.wflms.cn", forHTTPHeaderField: "Referer")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let loadedImage = UIImage(data: data) {
                    self.image = loadedImage
                    // Cache the image
                    ImageCache.shared.set(image: loadedImage, for: imageURL.absoluteString)
                } else {
                    loadFailed = true
                }
            }
        }.resume()
    }
}

struct HTMLContentView: View {
    let htmlContent: String
    
    var body: some View {
        Text(attributedString)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var attributedString: AttributedString {
        do {
            // Process HTML content more safely
            let processedHTML = htmlContent
                .replacingOccurrences(of: "<br>", with: "\n")
                .replacingOccurrences(of: "<br/>", with: "\n")
                .replacingOccurrences(of: "<br />", with: "\n")
            
            if let data = processedHTML.data(using: .utf8) {
                return try AttributedString(
                    NSAttributedString(
                        data: data,
                        options: [.documentType: NSAttributedString.DocumentType.html],
                        documentAttributes: nil
                    )
                )
            }
        } catch {
            // Handle error silently
        }
        
        // Fallback to plain text if HTML parsing fails
        let plainText = htmlContent
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        return AttributedString(plainText)
    }
}

// Simple image cache to improve performance
class ImageCache {
    static let shared = ImageCache()
    
    private var cache = NSCache<NSString, UIImage>()
    
    func set(image: UIImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
    
    func get(url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
