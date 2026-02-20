import Foundation
import AppKit

// MARK: - Response Models
struct OllamaResponse: Codable {
    let message: OllamaMessage
}

struct OllamaMessage: Codable {
    let content: String
}

struct ScreenContext: Codable {
    let status: String
    let app: String
    let summary: String
}

// MARK: - Screen Analysis Service
class ScreenAnalysisService {
    // Base URL for Ollama
    private let ollamaURL = URL(string: "http://127.0.0.1:11434/api/chat")!
    
    private let modelName = "llama3.2-vision:11b"
    
    // Function to Analyze Screen Context (Module C)
    func analyzeScreenContext(image: NSImage) async throws -> ScreenContext {
        
        // RESIZE IMAGE
        guard let resizedImage = image.resized(toWidth: 448),
              let jpegData = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "ScreenAnalysisService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }
        
        let base64Image = jpegData.base64EncodedString()
        
        
        // TODO: User has to input their work. Because when a social Media Worker uses Instagram, it is not neccessarily a distraction.
        let prompt = """
        You are an agent monitoring a knowledge worker's screen. Your aim is to determine, if the worker is distracted or not. 
        Analyze this screenshot. Determine the active application and categorize the activity.
        
        Here is a set of non-exhaustive rules.
        RULES:
        - Coding (VS Code, Xcode, Terminal) -> "work"
        - Reading Documentation -> "work"
        - Shopping (Amazon, eBay) -> "distracted"
        - Social Media (Twitter, Facebook, Reddit) -> "distracted"
        - Entertainment (YouTube, Netflix) -> "distracted"
        
        Reply ONLY with this JSON structure:
        {
            "status": "work" OR "distracted",
            "app": "Application Name",
            "summary": "1 sentence description of activity. Start the sentence with "The user is".
        }
        """
        
        let payload: [String: Any] = [
            "model": modelName,
            "messages": [
                [
                    "role": "user",
                    "content": prompt,
                    "images": [base64Image]
                ]
            ],
            "stream": false,
            "format": "json",
            "options": [
                "temperature": 0.0, // Deterministic
                "num_ctx": 4096,
                "num_predict": 256
            ]
        ]
        
      
        print("Sending request...")
        var request = URLRequest(url: ollamaURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 120 
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
             if let responseString = String(data: data, encoding: .utf8) {
                 print("Ollama Error Response: \(responseString)")
             }
             throw NSError(domain: "ScreenAnalysisService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ollama request failed"])
        }
        
        // Parse Response
        // let fullREsponse = try JSONDecoder().decode(from: data)
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        let content = ollamaResponse.message.content
        
        guard let contentData = content.data(using: .utf8) else {
             throw NSError(domain: "ScreenAnalysisService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to encode content to data"])
        }
        
        let context = try JSONDecoder().decode(ScreenContext.self, from: contentData)
        return context
    }
}

// MARK: - Image Extensions for Resizing
extension NSImage {
    func resized(toWidth newWidth: CGFloat) -> NSImage? {
        let ratio = newWidth / self.size.width
        let newHeight = self.size.height * ratio
        let newSize = NSSize(width: newWidth, height: newHeight)
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high

        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
    
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
