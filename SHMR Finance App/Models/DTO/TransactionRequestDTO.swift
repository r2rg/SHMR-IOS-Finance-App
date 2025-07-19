//
//  TransactionRequestDTO.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 18.07.2025.
//

import Foundation

struct TransactionRequestDTO: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String?

    enum CodingKeys: String, CodingKey {
        case accountId
        case categoryId
        case amount
        case transactionDate
        case comment
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(amount, forKey: .amount)
        try container.encode(transactionDate, forKey: .transactionDate)
        if let comment = comment {
            try container.encode(comment, forKey: .comment)
        } else {
            try container.encodeNil(forKey: .comment)
        }
    }
}

extension TransactionRequestDTO {
    init(from transaction: Transaction) {
        self.accountId = transaction.accountId
        self.categoryId = transaction.categoryId
        self.amount = String(format: "%.2f", NSDecimalNumber(decimal: transaction.amount).doubleValue)
        self.transactionDate = transaction.transactionDate
        self.comment = transaction.comment
    }

    func toDomain(id: Int, createdAt: Date = Date(), updatedAt: Date = Date()) -> Transaction? {
        guard let amountDecimal = Decimal(string: amount) else { return nil }
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amountDecimal,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
