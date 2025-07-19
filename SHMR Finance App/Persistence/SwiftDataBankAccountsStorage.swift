import Foundation
import SwiftData

@MainActor
final class SwiftDataBankAccountsStorage: BankAccountsStorageProtocol {
    typealias BankAccountType = BankAccount
    private let context: ModelContext
    
    init(container: ModelContainer) {
        self.context = container.mainContext
    }
    
    func fetchAccount(id: Int) async throws -> BankAccount? {
        let fetchDescriptor = FetchDescriptor<BankAccountModel>(predicate: #Predicate { $0.id == id })
        guard let model = try context.fetch(fetchDescriptor).first else { return nil }
        return BankAccount(
            id: model.id,
            userId: model.userId,
            name: model.name,
            balance: model.balance,
            currency: model.currency,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
    
    func createAccount(_ account: BankAccount) async throws {
        let model = BankAccountModel(
            id: account.id,
            userId: account.userId,
            name: account.name,
            balance: account.balance,
            currency: account.currency,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt
        )
        context.insert(model)
        try context.save()
    }
    
    func updateAccount(_ account: BankAccount) async throws {
        let fetchDescriptor = FetchDescriptor<BankAccountModel>(predicate: #Predicate { $0.id == account.id })
        guard let model = try context.fetch(fetchDescriptor).first else { return }
        model.userId = account.userId
        model.name = account.name
        model.balance = account.balance
        model.currency = account.currency
        model.createdAt = account.createdAt
        model.updatedAt = account.updatedAt
        try context.save()
    }
    
    func deleteAccount(id: Int) async throws {
        let fetchDescriptor = FetchDescriptor<BankAccountModel>(predicate: #Predicate { $0.id == id })
        if let model = try context.fetch(fetchDescriptor).first {
            context.delete(model)
            try context.save()
        }
    }
    
    func changeBalance(id: Int, to newBalance: Decimal) async throws {
        let fetchDescriptor = FetchDescriptor<BankAccountModel>(predicate: #Predicate { $0.id == id })
        guard let model = try context.fetch(fetchDescriptor).first else { return }
        model.balance = newBalance
        try context.save()
    }
    
    func changeCurrency(id: Int, to newCurrency: String) async throws {
        let fetchDescriptor = FetchDescriptor<BankAccountModel>(predicate: #Predicate { $0.id == id })
        guard let model = try context.fetch(fetchDescriptor).first else { return }
        model.currency = newCurrency
        try context.save()
    }
    
    func fetchAllAccounts() async throws -> [BankAccount] {
        let fetchDescriptor = FetchDescriptor<BankAccountModel>()
        let models = try context.fetch(fetchDescriptor)
        return models.map { model in
            BankAccount(
                id: model.id,
                userId: model.userId,
                name: model.name,
                balance: model.balance,
                currency: model.currency,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            )
        }
    }
} 