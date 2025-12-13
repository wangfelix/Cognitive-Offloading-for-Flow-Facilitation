import Foundation

struct InferenceResponse: Codable, Sendable {
    let topic: String
    let summary: String
    let details: String
    let actionItems: [String]
}
