import Foundation

enum Direction: String, Codable, CaseIterable {
    case income
    case outcome
}

struct Category: Identifiable, Codable {
    let id: Int
    let name: String
    let emoji: Character
    let direction: Direction
    
    enum CodingKeys: CodingKey {
        case id, name, emoji, direction
    }
    
    init(id: Int, name: String, emoji: Character, direction: Direction) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.direction = direction
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let emojiString = try container.decode(String.self, forKey: .emoji)
        emoji = Character(emojiString)
        direction = try container.decode(Direction.self, forKey: .direction)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(String(emoji), forKey: .emoji)
        try container.encode(direction, forKey: .direction)
    }
}
