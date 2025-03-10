import SwiftUI

struct SchoolArrangementDetailView: View {
    let detail: SchoolArrangementDetail
    @State private var animateContent = false
    @State private var selectedImageIndex: Int?
    @State private var showingFullScreenImage = false
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
                            ForEach(Array(detail.imageUrls.enumerated()), id: \.1) { index, imageUrlString in
                                if let imageUrl = URL(string: imageUrlString) {
                                    ImageThumbnail(url: imageUrl)
                                        .frame(height: 200)
                                        .frame(width: 280)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .contentShape(Rectangle())
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                        .onTapGesture {
                                            selectedImageIndex = index
                                            showingFullScreenImage = true
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
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let index = selectedImageIndex, index < detail.imageUrls.count {
                ImageViewer(
                    imageUrl: detail.imageUrls[index],
                    title: detail.title,
                    date: detail.publishDate
                )
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

// Simple thumbnail for the image list
struct ImageThumbnail: View {
    let url: URL
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
                    .overlay {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text("Failed to load")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            @unknown default:
                Color.gray
            }
        }
    }
}

// Simplified full screen image viewer
struct ImageViewer: View {
    let imageUrl: String
    let title: String
    let date: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
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
                GeometryReader { geo in
                    if let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 1) {
                    // Single tap dismisses only if not zoomed in
                    if scale <= 1.1 {
                        dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if scale > 1.0 || offset != .zero {
                        Button {
                            withAnimation(.spring()) {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }
            }
            .background(Color.black)
        }
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
