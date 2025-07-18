//
//  AccountUpdateRequestDTO.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 17.07.2025.
//

struct AccountUpdateRequestDTO: Encodable {
    let name: String
    let balance: String
    let currency: String
}

extension AccountUpdateRequestDTO {
    init(from account: BankAccount) {
        self.name = account.name
        self.balance = String(describing: account.balance)
        self.currency = account.currency
    }
}
