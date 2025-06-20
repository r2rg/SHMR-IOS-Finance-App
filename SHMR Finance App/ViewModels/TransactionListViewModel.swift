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
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    private let bankAccountsService = BankAccountsService()
    
    var startOfToday = Calendar.current.startOfDay(for: Date())
    var endOfToday = Calendar.current.date(byAdding: .second, value: -1, to: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!)!
    var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Calendar.current.startOfDay(for: Date()))!
    var endDate = Calendar.current.date(byAdding: .second, value: -1, to: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!)!
    
    var selectedSort: SortCriteria = .dateAsc
    
    var currency: String = ""
    
    func loadTodaysTransactions(for direction: Direction) async throws{
        do {
            let allItems = try await load(from: startOfToday, to: endOfToday)
            self.loadedTransaction = allItems.filter { $0.category.direction == direction }
        } catch {
            print("Failed to load: \(error)")
        }
    }
    
    func loadTransactions(for direction: Direction) async throws{
        do {
            let allItems = try await load(from: startDate, to: endDate)
            self.loadedTransaction = allItems.filter { $0.category.direction == direction }
        } catch {
            print("Failed to load: \(error)")
        }
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
            return loadedTransaction.sorted { $0.transaction.createdAt > $1.transaction.createdAt }
        case .dateDesc:
            return loadedTransaction.sorted { $0.transaction.createdAt < $1.transaction.createdAt }
        case .sumAsc:
            return loadedTransaction.sorted { $0.transaction.amount > $1.transaction.amount }
        case .sumDesc:
            return loadedTransaction.sorted { $0.transaction.amount < $1.transaction.amount }
        }
    }
    
    private func load(from startDate: Date, to endDate: Date) async throws -> [TransactionViewItem] {
        let transactions = try await transactionsService.getTransactions(from: startDate, to: endDate)
        let categories = try await categoriesService.allCategories()
        
        let categoriesById = Dictionary(uniqueKeysWithValues: categories.map{ ($0.id, $0) })
        
        let loadedItems = transactions.map { transaction in
            TransactionViewItem(
                id: transaction.id,
                transaction: transaction,
                category: categoriesById[transaction.categoryId]!
            )
        }
        
        return loadedItems
    }
}
