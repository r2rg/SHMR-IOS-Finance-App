import Foundation

final class TransactionsService {

    func getTransactions(from: Date, to: Date) async throws -> [Transaction] {
        print("Мок: Запрос транзакций с \(from) по \(to)")
        return [
            Transaction(
                id: 101,
                accountId: 1,
                categoryId: 2,
                amount: Decimal(string: "750.50")!,
                transactionDate: Date(),
                comment: "Покупка в супермаркете",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Transaction(
                id: 102,
                accountId: 1,
                categoryId: 1,
                amount: Decimal(string: "90000.00")!,
                transactionDate: Date().addingTimeInterval(-86400 * 2),
                comment: "Зарплата за месяц",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }

    func createTransaction(_ transaction: Transaction) async throws {
        print("Мок: Создание транзакции '\(transaction.comment ?? "Без комментария")' на сумму \(transaction.amount)")
    }
    
    func editTransaction(_ transaction: Transaction) async throws {
        print("Мок: Редактирование транзакции ID: \(transaction.id)")
    }

    func deleteTransaction(byId id: Int) async throws {
        print("Мок: Удаление транзакции ID: \(id)")
    }
}
