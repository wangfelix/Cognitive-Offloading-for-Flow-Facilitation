//
//  Item.swift
//  Flow Buddy
//
//  Created by Felix Wang on 19.11.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
