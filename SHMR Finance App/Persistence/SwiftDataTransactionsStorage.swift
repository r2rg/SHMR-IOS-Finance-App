import Foundation
import SwiftData

@MainActor
final class SwiftDataTransactionsStorage: TransactionsStorageProtocol {
    typealias TransactionType = Transaction
    private let context: ModelContext
    
    init(container: ModelContainer) {
        self.context = container.mainContext
    }
    
    func fetchTransactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let fetchDescriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.accountId == accountId && $0.transactionDate >= startDate && $0.transactionDate <= endDate }
        )
        let models = try context.fetch(fetchDescriptor)
        return models.map { model in
            Transaction(
                id: model.id,
                accountId: model.accountId,
                categoryId: model.categoryId,
                amount: model.amount,
                transactionDate: model.transactionDate,
                comment: model.comment,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            )
        }
    }
    
    func fetchTransaction(id: Int) async throws -> Transaction? {
        let fetchDescriptor = FetchDescriptor<TransactionModel>(predicate: #Predicate { $0.id == id })
        guard let model = try context.fetch(fetchDescriptor).first else { return nil }
        return Transaction(
            id: model.id,
            accountId: model.accountId,
            categoryId: model.categoryId,
            amount: model.amount,
            transactionDate: model.transactionDate,
            comment: model.comment,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
    
    func createTransaction(_ transaction: Transaction) async throws {
        let fetchDescriptor = FetchDescriptor<TransactionModel>(predicate: #Predicate { $0.id == transaction.id })
        if let existing = try context.fetch(fetchDescriptor).first {
            // Обновляем существующую запись
            existing.accountId = transaction.accountId
            existing.categoryId = transaction.categoryId
            existing.amount = transaction.amount
            existing.transactionDate = transaction.transactionDate
            existing.comment = transaction.comment
            existing.createdAt = transaction.createdAt
            existing.updatedAt = transaction.updatedAt
        } else {
            // Вставляем новую
            let model = TransactionModel(
                id: transaction.id,
                accountId: transaction.accountId,
                categoryId: transaction.categoryId,
                amount: transaction.amount,
                transactionDate: transaction.transactionDate,
                comment: transaction.comment,
                createdAt: transaction.createdAt,
                updatedAt: transaction.updatedAt
            )
            context.insert(model)
        }
        try context.save()
    }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        let fetchDescriptor = FetchDescriptor<TransactionModel>(predicate: #Predicate { $0.id == transaction.id })
        guard let model = try context.fetch(fetchDescriptor).first else { return }
        model.accountId = transaction.accountId
        model.categoryId = transaction.categoryId
        model.amount = transaction.amount
        model.transactionDate = transaction.transactionDate
        model.comment = transaction.comment
        model.createdAt = transaction.createdAt
        model.updatedAt = transaction.updatedAt
        try context.save()
    }
    
    func deleteTransaction(id: Int) async throws {
        let fetchDescriptor = FetchDescriptor<TransactionModel>(predicate: #Predicate { $0.id == id })
        if let model = try context.fetch(fetchDescriptor).first {
            context.delete(model)
            try context.save()
        }
    }
} 