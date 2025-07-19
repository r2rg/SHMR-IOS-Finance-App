//
//  BankAccountDTO.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 17.07.2025.
//

import Foundation

struct AccountDTO: Identifiable, Codable {
    let id: Int
    let userId: Int
    let name: String
    let balance: String
    let currency: String
    let createdAt: Date
    let updatedAt: Date
}

extension AccountDTO {
    func toDomain() -> BankAccount? {
        guard let balance = Decimal(string: self.balance) else { return nil }
        return BankAccount(
            id: self.id,
            userId: self.userId,
            name: self.name,
            balance: balance,
            currency: self.currency,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}
