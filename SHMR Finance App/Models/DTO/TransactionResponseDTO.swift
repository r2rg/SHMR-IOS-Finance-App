//
//  TransactionResponseDTO.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 17.07.2025.
//

import Foundation

struct TransactionResponseDTO: Identifiable, Codable {
    let id: Int
    let account: AccountBriefDTO
    let category: CategoryDTO
    let amount: String
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
}

extension TransactionResponseDTO {
    func toDomain() -> Transaction? {
        guard let amountDecimal = Decimal(string: amount) else { return nil }
        return Transaction(
            id: id,
            accountId: account.id,
            categoryId: category.id,
            amount: amountDecimal,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
