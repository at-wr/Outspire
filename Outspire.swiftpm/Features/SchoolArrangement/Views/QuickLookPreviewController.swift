import SwiftUI
import QuickLook
import UIKit

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // Force reload if needed
        uiViewController.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: QuickLookPreview
        
        init(_ parent: QuickLookPreview) {
            self.parent = parent
            super.init()
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            print("DEBUG: Preparing to preview PDF at \(parent.url)")
            return parent.url as NSURL
        }
        
        func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
            print("DEBUG: QuickLook updated contents of preview item")
        }
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            print("DEBUG: QuickLook was dismissed")
        }
        
        func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for previewItem: QLPreviewItem) -> Bool {
            print("DEBUG: QuickLook asked to open URL: \(url)")
            // Allow opening the PDF
            return true
        }
    }
}
