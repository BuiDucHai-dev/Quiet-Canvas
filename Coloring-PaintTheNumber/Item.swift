//
//  Item.swift
//  Coloring-PaintTheNumber
//
//  Created by Hải on 5/10/26.
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
