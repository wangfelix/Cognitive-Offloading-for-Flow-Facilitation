import Foundation

// MARK: - Blablador API Request

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

// MARK: - Message

struct Message: Codable {
    let role: String
    let content: String
}

// MARK: - Blablador API Response

struct BlabladorResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }
}
