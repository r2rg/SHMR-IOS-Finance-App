import Foundation

final class TransactionsService {
    private var transactions = [
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
        )]

    func getTransactions(from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        return transactions.filter { $0.transactionDate > startDate && $0.transactionDate < endDate}
    }

    func createTransaction(_ transaction: Transaction) async throws {
        guard !transactions.contains(where: {$0.id == transaction.id} ) else {
            transactions.append(transaction)
            return
        }
    }
    
    func editTransaction(_ transaction: Transaction) async throws {
        guard let i = transactions.firstIndex(where: {$0.id == transaction.id}) else { return }
        transactions[i] = transaction
    }

    func deleteTransaction(byId id: Int) async throws {
        guard let i = transactions.firstIndex(where: {$0.id == id}) else { return }
        transactions.remove(at: i)
    }
}
