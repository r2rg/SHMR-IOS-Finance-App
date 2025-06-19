import Foundation

enum Direction {
    case income
    case outcome
}

struct Category: Identifiable {
    let id: Int
    let name: String
    let emoji: Character
    let direction: Direction
    
    enum CodingKeys: CodingKey {
        case id, name, emoji, direction
    }
}
