import Foundation

final class TransactionsService {
    private var transactions = [
        Transaction(
            id: 101,
            accountId: 1,
            categoryId: 1,
            amount: Decimal(string: "100000.00")!,
            transactionDate: Date(),
            comment: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 102,
            accountId: 1,
            categoryId: 2,
            amount: Decimal(string: "100000.00")!,
            transactionDate: Date(),
            comment: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 103,
            accountId: 1,
            categoryId: 3,
            amount: Decimal(string: "90000.00")!,
            transactionDate: Date().addingTimeInterval(-86400 * 4),
            comment: "Джек",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 104,
            accountId: 1,
            categoryId: 3,
            amount: Decimal(string: "90000.00")!,
            transactionDate: Date().addingTimeInterval(-86400 * 5),
            comment: "Джек",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 105,
            accountId: 1,
            categoryId: 4,
            amount: Decimal(string: "90000.00")!,
            transactionDate: Date(),
            comment: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 106,
            accountId: 1,
            categoryId: 5,
            amount: Decimal(string: "90000.00")!,
            transactionDate: Date().addingTimeInterval(-86400 * 32),
            comment: nil,
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
