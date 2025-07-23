//
//  TransactionListViewModel.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 20.06.2025.
//

import Foundation

struct TransactionViewItem: Identifiable {
    let id: Int
    let transaction: Transaction
    let category: Category
}

enum SortCriteria: String, CaseIterable, Identifiable {
    case dateAsc = "Дата ↑"
    case dateDesc = "Дата ↓"
    case sumAsc = "Сумма ↑"
    case sumDesc = "Сумма ↓"
    
    var id: String { self.rawValue }
}

@MainActor
@Observable
class TransactionItemViewModel {
    private var loadedTransaction = [TransactionViewItem]()
    
    private(set) var transactionViewItems = [TransactionViewItem]()
    private let transactionsService = TransactionsService.shared
    private let categoriesService = CategoriesService.shared
    private let bankAccountsService = BankAccountsService.shared
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    var accountId: Int? = nil
    var startOfToday = Calendar.current.startOfDay(for: Date())
    var endOfToday = Calendar.current.date(byAdding: .second, value: -1, to: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!)!
    var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Calendar.current.startOfDay(for: Date()))!
    var endDate = Calendar.current.date(byAdding: .second, value: -1, to: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!)!
    
    var selectedSort: SortCriteria = .dateAsc
    
    var currency: String = ""
    
    func loadTodaysTransactions(for direction: Direction) async throws{
        isLoading = true
        errorMessage = nil
        do {
            let account = try await bankAccountsService.getFirstAccount()
            let accountId = account.id
            let allItems = try await load(from: startOfToday, to: endOfToday, accountId: accountId)
            self.loadedTransaction = allItems.filter { $0.category.direction == direction }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            print("Failed to load: \(error)")
        }
        isLoading = false
    }
    
    func loadTransactions(for direction: Direction) async throws{
        isLoading = true
        errorMessage = nil
        do {
            let account = try await bankAccountsService.getFirstAccount()
            let accountId = account.id
            let allItems = try await load(from: startDate, to: endDate, accountId: accountId)
            self.loadedTransaction = allItems.filter { $0.category.direction == direction }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            print("Failed to load: \(error)")
        }
        isLoading = false
    }
    
    func getSum() -> Decimal{
        var sum: Decimal = 0
        
        for displayedTransaction in displayedTransactions {
            sum += displayedTransaction.transaction.amount
        }
        
        return sum
    }
    
    // Пока делаю так, потому что по условию у нас лишь один аккаунт
    func getCurrency() async {
        do {
            self.currency = try await bankAccountsService.getFirstAccount().currency
        } catch {
            print("Failed to load account: \(error)")
        }
    }
    
    var displayedTransactions: [TransactionViewItem]{
        switch(selectedSort){
        case .dateAsc:
            return loadedTransaction.sorted { $0.transaction.transactionDate > $1.transaction.transactionDate }
        case .dateDesc:
            return loadedTransaction.sorted { $0.transaction.transactionDate < $1.transaction.transactionDate }
        case .sumAsc:
            return loadedTransaction.sorted { $0.transaction.amount > $1.transaction.amount }
        case .sumDesc:
            return loadedTransaction.sorted { $0.transaction.amount < $1.transaction.amount }
        }
    }
    
    private func load(from startDate: Date, to endDate: Date, accountId: Int) async throws -> [TransactionViewItem] {
        let transactions = try await transactionsService.getTransactions(accountId: accountId, from: startDate, to: endDate)
        let categories = try await categoriesService.allCategories()
        
        let categoriesById = Dictionary(uniqueKeysWithValues: categories.map{ ($0.id, $0) })
        
        let loadedItems = transactions.map { transaction in
            TransactionViewItem(
                id: transaction.id,
                transaction: transaction,
                category: categoriesById[transaction.categoryId]! // Возможен крэш. Необзодимо исправить
            )
        }
        
        return loadedItems
    }
}
