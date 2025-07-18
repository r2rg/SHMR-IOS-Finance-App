//
//  CategoryDTO.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 17.07.2025.
//

struct CategoryDTO: Identifiable, Codable {
    let id: Int
    let name: String
    let emoji: String
    let isIncome: Bool
}

extension CategoryDTO {
    func toDomain() -> Category? {
        guard let emojiChar = emoji.first else { return nil }
        let direction: Direction = isIncome ? .income : .outcome
        return Category(
            id: id,
            name: name,
            emoji: emojiChar,
            direction: direction
        )
    }
}
