import Foundation

struct BankAccount: Identifiable, Codable {
    let id: Int
    let userId: Int
    let name: String
    let balance: Decimal
    let currency: String
    let createdAt: Date
    let updatedAt: Date
}

extension BankAccount {
    init?(dto: AccountDTO) {
        guard let balance = Decimal(string: dto.balance) else { return nil }
        self.id = dto.id
        self.userId = dto.userId
        self.name = dto.name
        self.balance = balance
        self.currency = dto.currency
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}
