import Foundation

protocol TransactionsStorageProtocol {
    associatedtype TransactionType
    func fetchTransactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [TransactionType]
    func fetchTransaction(id: Int) async throws -> TransactionType?
    func createTransaction(_ transaction: TransactionType) async throws
    func updateTransaction(_ transaction: TransactionType) async throws
    func deleteTransaction(id: Int) async throws
} 