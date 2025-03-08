import Foundation
import Vision
import UIKit
import CoreImage

class CaptchaRecognizer {
    enum RecognitionMethod {
        case basic
        case contrastEnhanced
        case binarized
        case combined // Tries all methods
    }
    
    static func recognizeText(in imageData: Data, method: RecognitionMethod = .combined, completion: @escaping (String?) -> Void) {
        guard let uiImage = UIImage(data: imageData) else {
            completion(nil)
            return
        }
        
        switch method {
        case .basic:
            performRecognition(on: uiImage, completion: completion)
        case .contrastEnhanced:
            let processed = enhanceContrast(image: uiImage)
            performRecognition(on: processed, completion: completion)
        case .binarized:
            let processed = binarizeImage(image: uiImage)
            performRecognition(on: processed, completion: completion)
        case .combined:
            // Try all methods and combine results for best accuracy
            var results: [String] = []
            let group = DispatchGroup()
            
            // Original image
            group.enter()
            performRecognition(on: uiImage) { result in
                if let text = result { results.append(text) }
                group.leave()
            }
            
            // Contrast enhanced
            group.enter()
            let contrastImage = enhanceContrast(image: uiImage)
            performRecognition(on: contrastImage) { result in
                if let text = result { results.append(text) }
                group.leave()
            }
            
            // Binarized
            group.enter()
            let binaryImage = binarizeImage(image: uiImage)
            performRecognition(on: binaryImage) { result in
                if let text = result { results.append(text) }
                group.leave()
            }
            
            // Scale 2x
            group.enter()
            if let scaledImage = scaleImage(uiImage, by: 2.0) {
                performRecognition(on: scaledImage) { result in
                    if let text = result { results.append(text) }
                    group.leave()
                }
            } else {
                group.leave()
            }
            
            group.notify(queue: .main) {
                // Find most common result or longest valid result
                let bestGuess = findBestResult(from: results)
                completion(bestGuess)
            }
        }
    }
    
    private static func performRecognition(on image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        // Create a request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create text recognition request with specialized settings for captchas
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            // Extract and process text
            let recognizedStrings = observations.compactMap { observation -> String? in
                // Get multiple candidates to improve chances
                let candidates = observation.topCandidates(5)
                return candidates.first?.string
            }
            
            // Join and filter text
            let text = recognizedStrings.joined()
            
            // Filter to likely captcha characters (alphanumeric)
            let filteredText = text.filter { $0.isLetter || $0.isNumber }
            
            // Most captchas are 4-6 characters
            let captchaText = String(filteredText.prefix(6))
            
            completion(captchaText.isEmpty ? nil : captchaText)
        }
        
        // Configure for captcha recognition
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"] // Focus on English characters
        request.usesLanguageCorrection = false // Disable language correction (important for captchas)
        request.customWords = ["abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVXWYZ", "0123456789"] // Common captcha chars
        
        // Perform the request
        try? requestHandler.perform([request])
    }
    
    // MARK: - Image Processing Methods
    
    private static func enhanceContrast(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.5, forKey: kCIInputContrastKey) // Increase contrast
        filter.setValue(0.0, forKey: kCIInputSaturationKey) // Remove color
        filter.setValue(0.1, forKey: kCIInputBrightnessKey) // Slightly brighten
        
        if let outputImage = filter.outputImage,
           let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
    
    private static func binarizeImage(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        
        // First convert to grayscale
        let grayFilter = CIFilter(name: "CIColorControls")!
        grayFilter.setValue(ciImage, forKey: kCIInputImageKey)
        grayFilter.setValue(0.0, forKey: kCIInputSaturationKey)
        
        guard let grayImage = grayFilter.outputImage else { return image }
        
        // Then threshold to create binary image
        let thresholdFilter = CIFilter(name: "CIColorThreshold")!
        thresholdFilter.setValue(grayImage, forKey: kCIInputImageKey)
        thresholdFilter.setValue(0.5, forKey: "inputThreshold")
        
        if let outputImage = thresholdFilter.outputImage,
           let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
    
    private static func scaleImage(_ image: UIImage, by scale: CGFloat) -> UIImage? {
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    private static func findBestResult(from results: [String]) -> String? {
        guard !results.isEmpty else { return nil }
        
        // Filter for 4 character result
        let validResults = results.filter { 
            let filtered = $0.filter { $0.isLetter || $0.isNumber }
            // return filtered.count >= 4 && filtered.count <= 6 
            return filtered.count == 4 
        }
        
        if !validResults.isEmpty {
            // 1. Try to find the most common result first
            let counts = Dictionary(validResults.map { ($0, 1) }, uniquingKeysWith: +)
            if let (mostCommon, count) = counts.max(by: { $0.1 < $1.1 }), count > 1 {
                return mostCommon
            }
            
            // 2. If no consensus, return the first valid result
            return validResults.first
        }
        
        // 3. Fall back to any reasonable result
        let anyValid = results.compactMap { result -> String? in
            let filtered = result.filter { $0.isLetter || $0.isNumber }
            return filtered.isEmpty ? nil : String(filtered.prefix(4))
        }.first
        
        return anyValid
    }
}
