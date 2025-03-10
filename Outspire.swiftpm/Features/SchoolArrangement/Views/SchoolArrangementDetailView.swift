import SwiftUI

struct SchoolArrangementDetailView: View {
    let detail: SchoolArrangementDetail
    @State private var selectedImageURL: String?
    @State private var isShowingFullScreenImage = false
    
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
                            ForEach(detail.imageUrls, id: \.self) { imageUrl in
                                AsyncImage(url: URL(string: imageUrl)) { phase in
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
                                                selectedImageURL = imageUrl
                                                isShowingFullScreenImage = true
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
            .padding()
        }
        .navigationTitle("School Arrangement")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingFullScreenImage) {
            if let imageURL = selectedImageURL, let url = URL(string: imageURL) {
                FullScreenImageView(imageURL: url)
            }
        }
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
