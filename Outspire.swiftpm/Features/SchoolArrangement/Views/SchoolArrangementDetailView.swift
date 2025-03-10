import SwiftUI
import QuickLook

struct SchoolArrangementDetailView: View {
    let detail: SchoolArrangementDetail
    @State private var selectedURL: URL?
    @State private var isShowingPreview = false
    @State private var loadingImage = false
    
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
                
                // Images section
                if !detail.imageUrls.isEmpty {
                    Text("Attachments")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(detail.imageUrls, id: \.self) { imageUrlString in
                                if let imageUrl = URL(string: imageUrlString) {
                                    ImageWithReferer(url: imageUrl) { phase in
                                        switch phase {
                                        case .empty:
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(UIColor.tertiarySystemBackground))
                                                .overlay(
                                                    ProgressView()
                                                )
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .onTapGesture {
                                                    loadAndPreviewImage(from: imageUrlString)
                                                }
                                        case .failure:
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(UIColor.tertiarySystemBackground))
                                                .overlay(
                                                    Image(systemName: "exclamationmark.triangle")
                                                        .foregroundStyle(.secondary)
                                                )
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(height: 200)
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                                }
                            }
                        }
                    }
                }
                
                // Content section (if needed)
                if !detail.content.isEmpty {
                    Divider()
                    
                    Text("Description")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HTMLContentView(htmlContent: detail.content)
                }
            }
            .padding()
        }
        .navigationTitle("School Arrangement")
        .navigationBarTitleDisplayMode(.inline)
        .quickLookPreview($selectedURL)
        .overlay(
            loadingImage ? ProgressView("Loading image...").padding().background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)).shadow(radius: 5)) : nil
        )
    }
    
    private func loadAndPreviewImage(from urlString: String) {
        guard let sourceURL = URL(string: urlString) else { return }
        
        // Show loading indicator
        loadingImage = true
        
        // Create a proper request with referer header
        var request = URLRequest(url: sourceURL)
        request.addValue("https://www.wflms.cn", forHTTPHeaderField: "Referer")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // Hide the loading indicator
                loadingImage = false
                
                guard let data = data, error == nil else { return }
                
                // Create a temporary file
                let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                let fileName = sourceURL.lastPathComponent
                let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
                
                // Write to the temporary file
                do {
                    try data.write(to: fileURL)
                    self.selectedURL = fileURL
                    self.isShowingPreview = true
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
        task.resume()
    }
}

// Custom AsyncImage implementation with proper referer headers
struct ImageWithReferer<Content: View>: View {
    private let url: URL
    private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase = .empty
    
    init(url: URL, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
    }
    
    private func loadImage() {
        var request = URLRequest(url: url)
        request.addValue("https://www.wflms.cn", forHTTPHeaderField: "Referer")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.phase = .failure(error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.phase = .failure(NSError(domain: "ImageWithReferer", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                }
                return
            }
            
            if let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.phase = .success(Image(uiImage: uiImage))
                }
            } else {
                DispatchQueue.main.async {
                    self.phase = .failure(NSError(domain: "ImageWithReferer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"]))
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
            // Process HTML content and convert to AttributedString
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
        
        return AttributedString(htmlContent)
    }
}

struct FullScreenImageView: View {
    let imageURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        
                                        // Limit zoom scale between 1 and 5
                                        scale = min(max(1.0, scale * delta), 5.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Only allow panning when zoomed in
                                        if scale > 1.0 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .simultaneousGesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        withAnimation(.spring()) {
                                            if scale > 1.0 {
                                                // Reset zoom and position
                                                scale = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            } else {
                                                // Zoom in to 3x at current position
                                                scale = 3.0
                                            }
                                        }
                                    }
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failure:
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Failed to load image")
                                .foregroundStyle(.secondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .navigationTitle("Image Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
        }
        .preferredColorScheme(.dark)
    }
}
