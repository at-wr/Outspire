import SwiftUI
import QuickLook
import UIKit

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        
        // Ensure controller takes up full screen
        controller.modalPresentationStyle = .fullScreen
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
        
        // Make sure we open in full screen
        func previewControllerWillStartPresentation(_ controller: QLPreviewController) {
            controller.navigationController?.isNavigationBarHidden = true
        }
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            print("DEBUG: QuickLook was dismissed")
        }
    }
}
