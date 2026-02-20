import Foundation

// MARK: - Classification Response

private struct ReminderClassificationResponse: Codable {
    let isReminder: Bool
}

// MARK: - Reminder Detection Service

class ReminderDetectionService {
    
    private let baseURL = URL(string: "https://api.helmholtz-blablador.fz-juelich.de/v1/chat/completions")!
    // TODO: Replace with actual token or secure storage retrieval
    private let apiToken = "[INSERT YOUR TOKEN HERE]"

    /// Classifies whether the given text is a reminder or a research item.
    /// - Parameter text: The offloaded thought text to classify
    /// - Returns: `true` if the text is a reminder, `false` if it's a research item
    func classifyAsReminder(text: String) async throws -> Bool {
        
        let systemPrompt = """
            You are a classifier for an adaptive cognitive offloading system.
            
            **Your Task:**
            Determine whether the user's offloaded thought is a REMINDER or a RESEARCH item.
            
            **Definitions:**
            - **REMINDER**: A task, action, or to-do item that the user needs to remember to do later. Examples:
              - "Remind me to call mom"
              - "Buy groceries"
              - "Schedule dentist appointment"
              - "Reply to John's email"
              - "Pick up dry cleaning"
            
            - **RESEARCH**: A question, topic, or concept that requires looking up information or learning. Examples:
              - "What is quantum computing?"
              - "Look up RNN architectures"
              - "How does photosynthesis work?"
              - "Check price of MacBook Pro"
              - "Compare React vs Vue"
            
            **Instructions:**
            1. Analyze the user's input
            2. Classify it as either a reminder or research item
            3. Respond ONLY with a JSON object in this exact format:
            
            {"isReminder": true}  or  {"isReminder": false}
            
            Do not include any other text or explanation.
            """
          
        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: text)
        ]

        let payload = BlabladorRequest(
            model: "alias-fast",
            messages: messages,
            temperature: 0.1,
            topP: 1.0,
            topK: -1,
            n: 1,
            maxTokens: 50,
            stop: nil,
            stream: false,
            presencePenalty: 0,
            frequencyPenalty: 0,
            user: "macos-client",
            seed: 42
        )

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                 print("ReminderDetectionService Error: \(responseString)")
            }
            throw NSError(domain: "ReminderDetectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Request failed"])
        }

        let blabladorResponse = try JSONDecoder().decode(BlabladorResponse.self, from: data)
        
        guard let firstChoice = blabladorResponse.choices.first else {
             throw NSError(domain: "ReminderDetectionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No choices returned"])
        }

        var content = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if content.hasPrefix("```json") {
            content = content.replacingOccurrences(of: "```json", with: "")
        }
        if content.hasPrefix("```") {
             content = content.replacingOccurrences(of: "```", with: "")
        }
        if content.hasSuffix("```") {
             content = String(content.dropLast(3))
        }
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = content.data(using: .utf8) else {
             throw NSError(domain: "ReminderDetectionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to convert content to data"])
        }
        
        let classificationResponse = try JSONDecoder().decode(ReminderClassificationResponse.self, from: jsonData)
        return classificationResponse.isReminder
    }
}
