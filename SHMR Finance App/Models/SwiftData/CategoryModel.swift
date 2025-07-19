import Foundation
import SwiftData

@Model
final class CategoryModel {
    @Attribute(.unique) var id: Int
    var name: String
    var emoji: String
    var direction: String
    
    init(id: Int, name: String, emoji: String, direction: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.direction = direction
    }
} 