//
//  TransactionEditViewModel.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 15.07.2025.
//

import SwiftUI

@Observable
class TransactionEditViewModel {
    // MARK: - Input Properties
    let mode: EditMode
    let direction: Direction
    let transaction: Transaction?

    // MARK: - State
    var selectedCategory: Category?
    var amount: String = ""
    var selectedDate: Date = Date()
    var selectedTime: Date = Date()
    var comment: String = ""
    var showingCategoryPicker = false
    var showingAmountAlert = false
    var showingValidationAlert = false
    var categories: [Category] = []
    var account: BankAccount?
    var shouldDismiss: Bool = false

    // MARK: - Services
    private let transactionsService = TransactionsService.shared
    private let categoriesService = CategoriesService.shared
    private let bankAccountsService = BankAccountsService.shared

    // MARK: - Init
    init(mode: EditMode, direction: Direction, transaction: Transaction? = nil) {
        self.mode = mode
        self.direction = direction
        self.transaction = transaction
    }

    // MARK: - Data Loading
    @MainActor
    func loadData() async {
        do {
            categories = try await categoriesService.categories(for: direction)
            account = try await bankAccountsService.getFirstAccount()

            if let transaction = transaction {
                selectedCategory = categories.first { $0.id == transaction.categoryId }
                amount = String(describing: transaction.amount)
                selectedDate = transaction.transactionDate
                selectedTime = transaction.transactionDate
                comment = transaction.comment ?? ""
            }
        } catch {
            print("Failed to load data: \(error)")
        }
    }

    // MARK: - Formatting & Validation
    func formatAmount(_ input: String) -> String {
        let filtered = input.filter { char in
            char.isNumber || char == Locale.current.decimalSeparator?.first
        }
        let separator = Locale.current.decimalSeparator ?? "."
        let components = filtered.components(separatedBy: separator)
        if components.count > 2 {
            let firstPart = components[0]
            let secondPart = components.dropFirst().joined()
            return firstPart + separator + secondPart
        }
        return filtered
    }

    func validateFields() -> Bool {
        guard selectedCategory != nil,
              !amount.isEmpty else {
            showingValidationAlert = true
            return false
        }
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        guard let _ = formatter.number(from: amount) else {
            showingValidationAlert = true
            return false
        }
        return true
    }

    // MARK: - Transaction Operations
    func saveTransaction() {
        guard validateFields(),
              let category = selectedCategory,
              let account = account else {
            return
        }
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        guard let number = formatter.number(from: amount),
              let amountDecimal = Decimal(string: number.stringValue) else {
            showingValidationAlert = true
            return
        }
        Task {
            do {
                let combinedDateTime = Calendar.current.date(
                    bySettingHour: Calendar.current.component(.hour, from: selectedTime),
                    minute: Calendar.current.component(.minute, from: selectedTime),
                    second: 0,
                    of: selectedDate
                ) ?? selectedDate
                if mode == .edit, let transaction = transaction {
                    let updatedTransaction = Transaction(
                        id: transaction.id,
                        accountId: transaction.accountId,
                        categoryId: category.id,
                        amount: amountDecimal,
                        transactionDate: combinedDateTime,
                        comment: comment.isEmpty ? nil : comment,
                        createdAt: transaction.createdAt,
                        updatedAt: Date()
                    )
                    try await transactionsService.editTransaction(updatedTransaction)
                } else {
                    let newId = generateUniqueId()
                    let newTransaction = Transaction(
                        id: newId,
                        accountId: account.id,
                        categoryId: category.id,
                        amount: amountDecimal,
                        transactionDate: combinedDateTime,
                        comment: comment.isEmpty ? nil : comment,
                        createdAt: combinedDateTime,
                        updatedAt: combinedDateTime
                    )
                    try await transactionsService.createTransaction(newTransaction)
                }
                await MainActor.run {
                    self.shouldDismiss = true
                }
            } catch {
                print("Failed to save transaction: \(error)")
                await MainActor.run {
                    self.showingAmountAlert = true
                }
            }
        }
    }

    func generateUniqueId() -> Int {
        let existingIds = Set([101, 102, 103, 104, 105, 106])
        var newId = 1000
        while existingIds.contains(newId) {
            newId += 1
        }
        return newId
    }

    func deleteTransaction() {
        guard let transaction = transaction else {
            return
        }
        Task {
            do {
                try await transactionsService.deleteTransaction(byId: transaction.id)
                await MainActor.run {
                    self.shouldDismiss = true
                }
            } catch {
                print("Failed to delete transaction: \(error)")
                await MainActor.run {
                    self.showingAmountAlert = true
                }
            }
        }
    }
}
