import UIKit
import PDFKit

class PDFGenerator {
    static func generatePDF(title: String, date: String, content: String, images: [UIImage]) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Outspire",
            kCGPDFContextAuthor: "Outspire App",
            kCGPDFContextTitle: title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        do {
            let data = try renderer.pdfData { (context) in
                context.beginPage()
                
                // Title configuration
                let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont
                ]
                
                // Draw title
                let titleStringSize = title.size(withAttributes: titleAttributes)
                let titleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: titleStringSize.height)
                title.draw(in: titleRect, withAttributes: titleAttributes)
                
                // Draw date
                let dateFont = UIFont.systemFont(ofSize: 14.0)
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: dateFont,
                    .foregroundColor: UIColor.darkGray
                ]
                let dateRect = CGRect(x: 50, y: titleRect.maxY + 10, width: pageRect.width - 100, height: 20)
                date.draw(in: dateRect, withAttributes: dateAttributes)
                
                var yPos = dateRect.maxY + 30
                
                // Add content if not empty
                if !content.isEmpty {
                    // Process HTML content to plain text
                    let processedContent = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    
                    let contentFont = UIFont.systemFont(ofSize: 12.0)
                    let contentAttributes: [NSAttributedString.Key: Any] = [
                        .font: contentFont
                    ]
                    
                    let contentStringSize = processedContent.size(withAttributes: contentAttributes)
                    let contentHeight = min(200, contentStringSize.height) // Limit content height
                    
                    let contentRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: contentHeight)
                    processedContent.draw(in: contentRect, withAttributes: contentAttributes)
                    
                    yPos = contentRect.maxY + 30
                }
                
                // Add images
                for (index, image) in images.enumerated() {
                    // Start a new page if not enough space
                    if yPos + 250 > pageRect.height {
                        context.beginPage()
                        yPos = 50 // Reset Y position for new page
                    }
                    
                    // Calculate image size while maintaining aspect ratio
                    let maxWidth: CGFloat = pageRect.width - 100
                    let maxHeight: CGFloat = 250
                    
                    let aspectRatio = image.size.width / image.size.height
                    let imageWidth: CGFloat
                    let imageHeight: CGFloat
                    
                    if aspectRatio > 1 { // Landscape
                        imageWidth = min(maxWidth, image.size.width)
                        imageHeight = imageWidth / aspectRatio
                    } else { // Portrait
                        imageHeight = min(maxHeight, image.size.height)
                        imageWidth = imageHeight * aspectRatio
                    }
                    
                    // Center the image
                    let xPos = (pageRect.width - imageWidth) / 2
                    
                    let imageRect = CGRect(x: xPos, y: yPos, width: imageWidth, height: imageHeight)
                    image.draw(in: imageRect)
                    
                    // Add image number text below the image
                    let imageNumberFont = UIFont.systemFont(ofSize: 10.0)
                    let imageNumberAttributes: [NSAttributedString.Key: Any] = [
                        .font: imageNumberFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    
                    let imageNumberText = "Image \(index + 1) of \(images.count)"
                    let imageNumberRect = CGRect(x: 50, y: yPos + imageHeight + 5, width: pageRect.width - 100, height: 15)
                    imageNumberText.draw(in: imageNumberRect, withAttributes: imageNumberAttributes)
                    
                    yPos = imageNumberRect.maxY + 30
                }
            }
            
            return data
        } catch {
            print("DEBUG: Error generating PDF: \(error)")
            return nil
        }
    }
}
