import UIKit
import PDFKit

class PDFGenerator {
    static func generatePDF(title: String, date: String, content: String, images: [UIImage]) -> Data? {
        print("DEBUG: Generating PDF with title: \(title), images: \(images.count)")

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
        let margin: CGFloat = 40.0
        let contentWidth = pageWidth - (margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        do {
            let data = try renderer.pdfData { (context) in
                // First page with title and content
                context.beginPage()

                // Draw title and date header
                var yPosition = drawHeader(
                    title: title,
                    date: date,
                    rect: pageRect,
                    margin: margin
                )

                // Add separator
                yPosition += 10.0 // Fixed: Use CGFloat literal
                drawSeparator(at: yPosition, width: pageWidth, margin: margin)
                yPosition += 20.0 // Fixed: Use CGFloat literal

                // Check if we have images to show
                if !images.isEmpty {
                    // Draw image section title
                    let sectionFont = UIFont.boldSystemFont(ofSize: 14)
                    let sectionAttributes: [NSAttributedString.Key: Any] = [
                        .font: sectionFont,
                        .foregroundColor: UIColor.darkGray
                    ]

                    let sectionTitle = "Attachments (\(images.count) images)"
                    let sectionRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 20)
                    sectionTitle.draw(in: sectionRect, withAttributes: sectionAttributes)
                    yPosition += 24.0 // Fixed: Use CGFloat literal

                    // Draw each image
                    for (index, image) in images.enumerated() {
                        print("DEBUG: Drawing image \(index+1) of \(images.count)")

                        // Check if we need a new page for this image
                        let estimatedImageHeight = min(300.0, image.size.height * (contentWidth / max(image.size.width, 1.0)))
                        if yPosition + estimatedImageHeight + 40.0 > pageHeight - margin { // Fixed: Use CGFloat literal
                            context.beginPage()
                            yPosition = margin
                        }

                        // Draw image number label
                        let imageNumFont = UIFont.boldSystemFont(ofSize: 12)
                        let imageNumAttributes: [NSAttributedString.Key: Any] = [
                            .font: imageNumFont,
                            .foregroundColor: UIColor.darkGray
                        ]

                        let imageLabel = "Image \(index+1) of \(images.count):"
                        imageLabel.draw(
                            at: CGPoint(x: margin, y: yPosition),
                            withAttributes: imageNumAttributes
                        )
                        yPosition += 20.0 // Fixed: Use CGFloat literal

                        // Draw the actual image
                        yPosition = drawImageWithCaptions(
                            image: image,
                            startY: yPosition,
                            pageRect: pageRect,
                            margin: margin,
                            contentWidth: contentWidth
                        )

                        // Add space between images
                        yPosition += 25.0 // Fixed: Use CGFloat literal

                        // Add a separator between images if not the last one
                        if index < images.count - 1 {
                            drawSeparator(at: yPosition, width: pageWidth, margin: margin + 20.0) // Fixed: Use CGFloat literal
                            yPosition += 20.0 // Fixed: Use CGFloat literal
                        }
                    }
                }

                // Add separator before content if we have images
                if !images.isEmpty {
                    if yPosition + 200.0 > pageHeight - margin { // Fixed: Use CGFloat literal
                        context.beginPage()
                        yPosition = margin
                    } else {
                        yPosition += 10.0 // Fixed: Use CGFloat literal
                        drawSeparator(at: yPosition, width: pageWidth, margin: margin)
                        yPosition += 20.0 // Fixed: Use CGFloat literal
                    }
                }

                // Add content section if we have any
                if !content.isEmpty {
                    // Content title
                    if yPosition + 100.0 > pageHeight - margin { // Fixed: Use CGFloat literal
                        context.beginPage()
                        yPosition = margin
                    }

                    let contentTitleFont = UIFont.boldSystemFont(ofSize: 14)
                    let contentTitleAttributes: [NSAttributedString.Key: Any] = [
                        .font: contentTitleFont,
                        .foregroundColor: UIColor.darkGray
                    ]

                    let contentTitle = "Description"
                    let contentTitleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 20)
                    contentTitle.draw(in: contentTitleRect, withAttributes: contentTitleAttributes)
                    yPosition += 24.0 // Fixed: Use CGFloat literal

                    // Draw the actual content
                    yPosition = drawHTMLContent(
                        content: content,
                        startY: yPosition,
                        pageRect: pageRect,
                        margin: margin,
                        context: context
                    )
                }
            }

            print("DEBUG: PDF generated successfully with \(images.count) images")
            return data
        } catch {
            print("DEBUG: Error generating PDF: \(error)")
            return nil
        }
    }

    private static func drawHeader(title: String, date: String, rect: CGRect, margin: CGFloat) -> CGFloat {
        var yPosition = margin + 10.0 // Fixed: Use CGFloat literal

        // Draw title
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont
        ]

        let titleWidth = rect.width - (margin * 2)
        let titleHeight = min(100, title.boundingRect(
            with: CGSize(width: titleWidth, height: 200),
            options: .usesLineFragmentOrigin,
            attributes: titleAttributes,
            context: nil
        ).height)

        let titleRect = CGRect(x: margin, y: yPosition, width: titleWidth, height: titleHeight)
        title.draw(in: titleRect, withAttributes: titleAttributes)

        yPosition += titleHeight + 8.0 // Fixed: Use CGFloat literal

        // Draw date
        let dateFont = UIFont.systemFont(ofSize: 12)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.darkGray
        ]

        let dateRect = CGRect(x: margin, y: yPosition, width: titleWidth, height: 16)
        date.draw(in: dateRect, withAttributes: dateAttributes)

        yPosition += 20.0 // Fixed: Use CGFloat literal

        return yPosition
    }

    private static func drawSeparator(at yPos: CGFloat, width: CGFloat, margin: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: yPos))
        path.addLine(to: CGPoint(x: width - margin, y: yPos))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private static func drawImageWithCaptions(image: UIImage, startY: CGFloat, pageRect: CGRect, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        var yPosition = startY

        // Calculate image dimensions to fit within page
        let aspectRatio = max(image.size.width, 1.0) / max(image.size.height, 1.0) // Fixed: Use CGFloat literal
        let maxImageHeight: CGFloat = 300.0 // Fixed: Use CGFloat literal
        let maxImageWidth = contentWidth

        var imageWidth: CGFloat
        var imageHeight: CGFloat

        if aspectRatio > 1 { // Landscape
            imageWidth = min(maxImageWidth, image.size.width)
            imageHeight = imageWidth / aspectRatio
        } else { // Portrait
            imageHeight = min(maxImageHeight, image.size.height)
            imageWidth = imageHeight * aspectRatio
        }

        // Don't let image be too big
        if imageHeight > maxImageHeight {
            imageHeight = maxImageHeight
            imageWidth = imageHeight * aspectRatio
        }
        if imageWidth > maxImageWidth {
            imageWidth = maxImageWidth
            imageHeight = imageWidth / aspectRatio
        }

        // Center the image
        let xPosition = margin + ((contentWidth - imageWidth) / 2)

        // Draw the image
        let imageRect = CGRect(x: xPosition, y: yPosition, width: imageWidth, height: imageHeight)
        image.draw(in: imageRect)

        yPosition += imageHeight + 5.0 // Fixed: Use CGFloat literal

        return yPosition
    }

    private static func drawHTMLContent(content: String, startY: CGFloat, pageRect: CGRect, margin: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var yPosition = startY

        // Strip HTML tags to get plain text
        let plainText = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")

        // Split into paragraphs
        let paragraphs = plainText.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let contentFont = UIFont.systemFont(ofSize: 12)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: UIColor.black
        ]

        let contentWidth = pageRect.width - (margin * 2)

        for paragraph in paragraphs {
            // Calculate height needed for this paragraph
            let paragraphHeight = paragraph.boundingRect(
                with: CGSize(width: contentWidth, height: 1000),
                options: .usesLineFragmentOrigin,
                attributes: contentAttributes,
                context: nil
            ).height

            // Check if we need a new page
            if yPosition + paragraphHeight > pageRect.height - margin {
                context.beginPage()
                yPosition = margin
            }

            // Draw the paragraph
            let paragraphRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: paragraphHeight)
            paragraph.draw(in: paragraphRect, withAttributes: contentAttributes)

            // Update position
            yPosition += paragraphHeight + 10.0 // Fixed: Use CGFloat literal
        }

        return yPosition
    }
}
