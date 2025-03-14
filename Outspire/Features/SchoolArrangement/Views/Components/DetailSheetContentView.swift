import SwiftUI
import QuickLook

struct DetailSheetContentView: View {
    let pdfURL: URL?
    let isLoadingDetail: Bool
    @Binding var showDetailSheet: Bool
    @Binding var errorMessage: String?
    
    var body: some View {
        Group {
            if let pdfURL = pdfURL {
                QuickLookPreview(url: pdfURL)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea()
            } else if isLoadingDetail {
                loadingView
            } else {
                errorView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Preparing document...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("Content Unavailable")
                .font(.headline)
            
            Text("Unable to load the requested content")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Dismiss") {
                showDetailSheet = false
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Auto-dismiss if no data loaded after a timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if pdfURL == nil && !isLoadingDetail {
                    showDetailSheet = false
                    errorMessage = "Failed to load content"
                }
            }
        }
    }
}
