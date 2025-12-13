import Foundation

struct BlabladorRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let topP: Double
    let topK: Int
    let n: Int
    let maxTokens: Int
    let stop: [String]?
    let stream: Bool
    let presencePenalty: Double
    let frequencyPenalty: Double
    let user: String
    let seed: Int?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case topP = "top_p"
        case topK = "top_k"
        case n
        case maxTokens = "max_tokens"
        case stop, stream
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case user, seed
    }
}

struct Message: Codable {
    let role: String
    let content: String
}



struct BlabladorResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }
}

class BackgroundResearchService {
    
    private let baseURL = URL(string: "https://api.helmholtz-blablador.fz-juelich.de/v1/chat/completions")!
    // TODO: Replace with actual token or secure storage retrieval
    private let apiToken = "YOUR_BLABLADOR_KEY"

    func performResearch(for query: String) async throws -> InferenceResponse {
        
        let systemPrompt = """
            You are part of an adaptive cognitive offloading system, which is an intelligent research assistant designed to support knowledge workers by handling offloaded thoughts.

            **Your Goal:**
            The user has "offloaded" a thought to you to avoid breaking their current Flow state. Your job is to process this thought and generate an actionable report that they can review later during a break, or after the session.

            **Context:**
            - The user is currently deep in a knowledge-intensive task (e.g., coding, writing).
            - The input prompts could be short, vague, or context-dependent (e.g., "Look up RNNs" or "check price of X").
            - You must use your internal knowledge to infer the most likely intent and provide a helpful response.
            - Since you are not a chatbot and are not designed to engage with the user (e.g.waiting for user responses etc.), you need to provide detailed responses directly. 

            **Instructions:**
            1. **Analyze Intent:** Determine if the user wants a definition, an explanation, a comparison or a price check.
            2. **Be Proactive:** If the prompt is vague, try to infer the users intend.
            3. **Format for Quick Reading:** The response should be using markdown format. Use bullet points, bold text, and clear headings. For mathematical equations, include LaTeX.
            4. **Tone:** Professional, concise, and helpful.

            **Output Format:**
            1. Please format your response exactly as a JSON object with these fields:
            {
              "topic": "Inferred Topic",
              "summary": "2-3 sentence overview",
              "details": "Deep and detailed explanations with Latex Support",
              "actionItems": ["Action 1", "Action 2", ...]
            }
            2. The actionItems should only be links to relevant websites, not full sentences.
            3. Add up to 5 relevant action items.
            """
        
        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: query)
        ]

        let payload = BlabladorRequest(
            model: "alias-large",
            messages: messages,
            temperature: 0.7,
            topP: 1.0,
            topK: -1,
            n: 1,
            maxTokens: 5000,
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
                 print("Blablador Error: \(responseString)")
            }
            throw NSError(domain: "BackgroundResearchService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Request failed"])
        }

        let blabladorResponse = try JSONDecoder().decode(BlabladorResponse.self, from: data)
        
        guard let firstChoice = blabladorResponse.choices.first else {
             throw NSError(domain: "BackgroundResearchService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No choices returned"])
        }

        var content = firstChoice.message.content
        
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
        
        guard let jsonData = content.data(using: .utf8) else {
             throw NSError(domain: "BackgroundResearchService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to convert content to data"])
        }
        
        return try JSONDecoder().decode(InferenceResponse.self, from: jsonData)
    }
}
