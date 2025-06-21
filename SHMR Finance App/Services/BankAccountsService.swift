import Foundation

final class BankAccountsService {
    private var account = BankAccount(
        id: 1,
        userId: 1,
        name: "Основной счёт",
        balance: Decimal(string: "12345.67")!,
        currency: "₽",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    func getFirstAccount() async throws -> BankAccount {
        return account
    }
    
    func changeBalance(to newBalance: Decimal) async throws {
        account = BankAccount(id: account.id,
                           userId: account.userId,
                           name: account.name,
                           balance: newBalance,
                           currency: account.currency,
                           createdAt: account.createdAt,
                           updatedAt: account.updatedAt)
    }
}

