import SwiftUI
import QuickLook

struct SchoolArrangementDetailView: View {
    let detail: SchoolArrangementDetail
    @State private var selectedURL: URL?
    @State private var isShowingPreview = false
    @State private var loadingImage = false
    @State private var animateContent = false
    @State private var showFullScreenImage = false
    @State private var selectedImageURL: URL?
    
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
                ImageViewerSheet(imageURL: imageURL)
            }
        }
        .onAppear {
            // Animate content when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateContent = true
            }
        }
        .overlay(
            loadingImage ? 
                ZStack {
                    Color.black.opacity(0.4)
                    ProgressView("Loading image...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)).shadow(radius: 5))
                }
                .edgesIgnoringSafeArea(.all) : nil
        )
    }
}

// Replacement for ImageWithReferer that's safer and more reliable
struct SafeImageView: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
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
        isLoading = true
        loadFailed = false
        
        var request = URLRequest(url: url)
        request.addValue("https://www.wflms.cn", forHTTPHeaderField: "Referer")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let loadedImage = UIImage(data: data) {
                    self.image = loadedImage
                } else {
                    loadFailed = true
                }
            }
        }.resume()
    }
}

struct ImageViewerSheet: View {
    let imageURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if loadFailed {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                        Text("Image failed to load")
                            .foregroundStyle(.white)
                    }
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(1.0, scale * delta), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
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
                                            scale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        } else {
                                            scale = 3.0
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        isLoading = true
        loadFailed = false
        
        var request = URLRequest(url: imageURL)
        request.addValue("https://www.wflms.cn", forHTTPHeaderField: "Referer")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let loadedImage = UIImage(data: data) {
                    self.image = loadedImage
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
