//
//  Item.swift
//  Stockly
//
//  Created by Mike Reghabi on 2025-03-01.
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
