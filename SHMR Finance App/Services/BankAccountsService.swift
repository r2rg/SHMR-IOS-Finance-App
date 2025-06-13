import Foundation

final class BankAccountsService {
    func getFirstAccount() async throws -> BankAccount {
        return BankAccount(
            id: 1,
            userId: 1,
            name: "Основной счёт",
            balance: Decimal(string: "12345.67")!,
            currency: "RUB",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func changeBalance(for accountId: Int, to newBalance: Decimal) async throws {
        
        print("Мок: Установка нового баланса для счета ID: \(accountId). Новый баланс: \(newBalance)")
    }
}

