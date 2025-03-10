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
        
        // Standard letter size
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Margins
        let margin: CGFloat = 50.0
        let contentWidth = pageWidth - (margin * 2)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        do {
            let data = try renderer.pdfData { (context) in
                
                // First page - title and initial content
                context.beginPage()
                var currentY = drawHeader(
                    title: title,
                    date: date,
                    rect: pageRect,
                    margin: margin
                )
                
                // Add horizontal rule
                currentY += 10
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: currentY))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
                UIColor.lightGray.setStroke()
                path.lineWidth = 0.5
                path.stroke()
                currentY += 20
                
                // Process content to plain text
                if !content.isEmpty {
                    currentY = drawContent(
                        content: content,
                        startY: currentY,
                        pageRect: pageRect,
                        margin: margin,
                        context: context
                    )
                    
                    // Add space after content
                    currentY += 20
                }
                
                // Add images if available
                if !images.isEmpty {
                    // Add a section title for images
                    let imageSectionFont = UIFont.boldSystemFont(ofSize: 16.0)
                    let imageSectionTitle = "Attachments (\(images.count) images)"
                    
                    let imageSectionAttributes: [NSAttributedString.Key: Any] = [
                        .font: imageSectionFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    
                    // Draw section title
                    let sectionTitleRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 20)
                    imageSectionTitle.draw(in: sectionTitleRect, withAttributes: imageSectionAttributes)
                    currentY += 25
                    
                    // Check if we need a new page for images
                    if currentY > pageHeight - 250 {
                        context.beginPage()
                        currentY = margin
                    }
                    
                    // Draw each image
                    for (index, image) in images.enumerated() {
                        // Check if we need a new page
                        if currentY + 280 > pageHeight {
                            context.beginPage()
                            currentY = margin
                        }
                        
                        // Draw the image
                        currentY = drawImage(
                            image: image,
                            index: index,
                            total: images.count,
                            startY: currentY,
                            pageRect: pageRect,
                            margin: margin
                        )
                        
                        // Add spacing between images
                        currentY += 30
                    }
                }
            }
            
            return data
        } catch {
            print("DEBUG: Error generating PDF: \(error)")
            return nil
        }
    }
    
    // Helper method to draw the header
    private static func drawHeader(title: String, date: String, rect: CGRect, margin: CGFloat) -> CGFloat {
        var currentY = margin
        
        // Title configuration
        let titleFont = UIFont.boldSystemFont(ofSize: 20.0)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont
        ]
        
        // Calculate title height based on available width
        let titleWidth = rect.width - (margin * 2)
        let titleSize = title.boundingRect(
            with: CGSize(width: titleWidth, height: 200),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: titleAttributes,
            context: nil
        ).size
        
        // Draw title
        let titleRect = CGRect(x: margin, y: currentY, width: titleWidth, height: titleSize.height)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        currentY += titleSize.height + 10
        
        // Draw date
        let dateFont = UIFont.systemFont(ofSize: 12.0)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateRect = CGRect(x: margin, y: currentY, width: titleWidth, height: 20)
        date.draw(in: dateRect, withAttributes: dateAttributes)
        currentY += 20
        
        return currentY
    }
    
    // Helper method to draw content
    private static func drawContent(content: String, startY: CGFloat, pageRect: CGRect, 
                                   margin: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = startY
        let contentWidth = pageRect.width - (margin * 2)
        
        // Process HTML to plain text
        let processedContent = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse content into paragraphs
        let paragraphs = processedContent.components(separatedBy: "\n")
        
        // Content font configuration
        let contentFont = UIFont.systemFont(ofSize: 12.0)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: UIColor.black
        ]
        
        for paragraph in paragraphs {
            if paragraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                currentY += 10 // Add space for empty paragraph
                continue
            }
            
            // Calculate paragraph height based on text
            let paragraphSize = paragraph.boundingRect(
                with: CGSize(width: contentWidth, height: 1000),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: contentAttributes,
                context: nil
            ).size
            
            // Check if we need a new page
            if currentY + paragraphSize.height > pageRect.height - margin {
                context.beginPage()
                currentY = margin
            }
            
            // Draw paragraph
            let paragraphRect = CGRect(x: margin, y: currentY, width: contentWidth, height: paragraphSize.height)
            paragraph.draw(in: paragraphRect, withAttributes: contentAttributes)
            
            currentY += paragraphSize.height + 8 // Add space after paragraph
        }
        
        return currentY
    }
    
    // Helper method to draw an image with caption
    private static func drawImage(image: UIImage, index: Int, total: Int, startY: CGFloat, 
                                 pageRect: CGRect, margin: CGFloat) -> CGFloat {
        var currentY = startY
        let contentWidth = pageRect.width - (margin * 2)
        
        // Calculate image size while maintaining aspect ratio
        let maxHeight: CGFloat = 220
        
        let aspectRatio = image.size.width / image.size.height
        let imageWidth: CGFloat
        let imageHeight: CGFloat
        
        if aspectRatio > 1 { // Landscape
            imageWidth = min(contentWidth, image.size.width)
            imageHeight = imageWidth / aspectRatio
        } else { // Portrait
            imageHeight = min(maxHeight, image.size.height)
            imageWidth = imageHeight * aspectRatio
        }
        
        // Ensure we're not exceeding max height
        let finalHeight = min(imageHeight, maxHeight)
        let finalWidth = aspectRatio > 1 ? finalHeight * aspectRatio : imageWidth
        
        // Center the image
        let xPos = margin + (contentWidth - finalWidth) / 2
        
        // Draw image
        let imageRect = CGRect(x: xPos, y: currentY, width: finalWidth, height: finalHeight)
        image.draw(in: imageRect)
        currentY += finalHeight + 5
        
        // Add caption below image
        let captionFont = UIFont.systemFont(ofSize: 10.0)
        let captionAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let caption = "Image \(index + 1) of \(total)"
        let captionSize = caption.boundingRect(
            with: CGSize(width: contentWidth, height: 50),
            options: [.usesLineFragmentOrigin],
            attributes: captionAttributes,
            context: nil
        ).size
        
        let captionRect = CGRect(
            x: margin,
            y: currentY,
            width: contentWidth,
            height: captionSize.height
        )
        
        caption.draw(in: captionRect, withAttributes: captionAttributes)
        currentY += captionSize.height
        
        return currentY
    }
}
