import SwiftData
import Foundation



@Model
class ThoughtItem {
    var id: UUID
    var text: String
    var categoryRaw: String
    var timestamp: Date
    
    var category: ThoughtCategory {
        get { ThoughtCategory(rawValue: categoryRaw) ?? .auto }
        set { categoryRaw = newValue.rawValue }
    }
    
    var hasBeenOpened: Bool = false
    
    var inferenceReportData: Data?
    
    var inferenceReport: InferenceResponse? {
        get {
            guard let data = inferenceReportData else { return nil }
            return try? JSONDecoder().decode(InferenceResponse.self, from: data)
        }
        set {
            inferenceReportData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(text: String, category: ThoughtCategory, timestamp: Date = Date(), hasBeenOpened: Bool = false) {
        self.id = UUID()
        self.text = text
        self.categoryRaw = category.rawValue
        self.timestamp = timestamp
        self.hasBeenOpened = hasBeenOpened
    }
}

