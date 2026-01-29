import AppKit
import Vision

/// Service for extracting text from images using Apple's Vision framework
@MainActor
final class OCRService {
    static let shared = OCRService()

    private init() {}

    /// Performs OCR on an image and returns the recognized text
    /// - Parameter image: The NSImage to extract text from
    /// - Returns: The recognized text, or nil if no text was found
    func recognizeText(in image: NSImage) async -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                let result = recognizedText.isEmpty ? nil : recognizedText
                continuation.resume(returning: result)
            }

            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            // Support multiple languages
            request.recognitionLanguages = ["en-US", "de-DE", "tr-TR", "fr-FR", "es-ES"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    /// Performs OCR on image data and returns the recognized text
    /// - Parameter data: The image data to extract text from
    /// - Returns: The recognized text, or nil if no text was found
    func recognizeText(in data: Data) async -> String? {
        guard let image = NSImage(data: data) else {
            return nil
        }
        return await recognizeText(in: image)
    }
}
