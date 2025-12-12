import SwiftData
import Foundation

@Model
class ThoughtItem {
    var id: UUID
    var text: String
    var categoryRaw: String
    var timestamp: Date
    
    var category: ThoughtCategory {
        get { ThoughtCategory(rawValue: categoryRaw) ?? .research }
        set { categoryRaw = newValue.rawValue }
    }
    
    var hasBeenOpened: Bool = false
    
    init(text: String, category: ThoughtCategory, timestamp: Date = Date(), hasBeenOpened: Bool = false) {
        self.id = UUID()
        self.text = text
        self.categoryRaw = category.rawValue
        self.timestamp = timestamp
        self.hasBeenOpened = hasBeenOpened
    }
}

