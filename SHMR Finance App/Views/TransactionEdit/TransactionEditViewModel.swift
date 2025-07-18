//
//  TransactionEditViewModel.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 15.07.2025.
//

import SwiftUI

@Observable
class TransactionEditViewModel {
    
    let mode: EditMode
    let direction: Direction
    let transaction: Transaction?

    var selectedCategory: Category?
    var amount: String = ""
    var selectedDate: Date = Date()
    var selectedTime: Date = Date()
    var comment: String = ""
    var showingCategoryPicker = false
    var showingAmountAlert = false
    var showingValidationAlert = false
    var validationMessage: String = "Пожалуйста, заполните все обязательные поля"
    var categories: [Category] = []
    var account: BankAccount?
    var shouldDismiss: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let transactionsService = TransactionsService.shared
    private let categoriesService = CategoriesService.shared
    private let bankAccountsService = BankAccountsService.shared

    init(mode: EditMode, direction: Direction, transaction: Transaction? = nil) {
        self.mode = mode
        self.direction = direction
        self.transaction = transaction
    }

    @MainActor
    func loadData() async {
        do {
            categories = try await categoriesService.categories(for: direction)
            account = try await bankAccountsService.getFirstAccount()

            if let transaction = transaction {
                selectedCategory = categories.first { $0.id == transaction.categoryId }
                amount = String(format: "%.2f", NSDecimalNumber(decimal: transaction.amount).doubleValue)
                selectedDate = transaction.transactionDate
                selectedTime = transaction.transactionDate
                comment = transaction.comment ?? ""
            }
        } catch {
            print("Failed to load data: \(error)")
        }
    }

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
        guard selectedCategory != nil else {
            validationMessage = "Пожалуйста, выберите статью"
            showingValidationAlert = true
            return false
        }
        
        guard !amount.isEmpty else {
            validationMessage = "Пожалуйста, введите сумму"
            showingValidationAlert = true
            return false
        }
        
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        
        guard let number = formatter.number(from: amount) else {
            validationMessage = "Пожалуйста, введите корректную сумму"
            showingValidationAlert = true
            return false
        }
        
        guard number.doubleValue > 0 else {
            validationMessage = "Сумма должна быть больше нуля"
            showingValidationAlert = true
            return false
        }
        
        return true
    }
    
    @MainActor
    func saveTransaction() async {
        guard validateFields(),
              let category = selectedCategory else {
            return
        }
        
        // Use the account we already loaded in `loadData()`
        guard let account = self.account else {
            errorMessage = "Аккаунт не был загружен. Пожалуйста, попробуйте снова."
            return
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        guard let number = formatter.number(from: amount),
              let amountDecimal = Decimal(string: String(format: "%.2f", number.doubleValue)) else {
            showingValidationAlert = true
            return
        }

        isLoading = true
        errorMessage = nil
        
        do {
                // --- Step 2: Assemble the Date with Zeroed Seconds/Nanoseconds (The Fix) ---
                let calendar = Calendar.current

                // Get Year, Month, Day from the date picker
                let datePortion = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                
                // Get Hour, Minute from the time picker
                let timePortion = calendar.dateComponents([.hour, .minute], from: selectedTime)

                // Create a new set of components to build the final date
                var finalComponents = DateComponents()
                finalComponents.year = datePortion.year
                finalComponents.month = datePortion.month
                finalComponents.day = datePortion.day
                finalComponents.hour = timePortion.hour
                finalComponents.minute = timePortion.minute
                
                // Explicitly set seconds and nanoseconds to 0 as requested.
                // This guarantees a consistent format for the server.
                finalComponents.second = 0
                finalComponents.nanosecond = 0
                
                // Build the final, full-precision date from our components
                guard let combinedDateTime = calendar.date(from: finalComponents) else {
                    // This should realistically never fail, but it's good practice to handle it.
                    errorMessage = "Не удалось сформировать дату."
                    isLoading = false
                    return
                }

            if mode == .edit, let transaction = transaction {
                let updatedTransaction = Transaction(
                    id: transaction.id,
                    accountId: account.id,
                    categoryId: category.id,
                    amount: amountDecimal,
                    transactionDate: combinedDateTime, // Use our perfectly assembled date
                    comment: comment.isEmpty ? nil : comment,
                    createdAt: transaction.createdAt,
                    updatedAt: Date()
                )
                _ = try await transactionsService.editTransaction(updatedTransaction)
            } else {
                let transactionDTO = TransactionRequestDTO(
                    accountId: account.id,
                    categoryId: category.id,
                    amount: amount,
                    transactionDate: combinedDateTime, // Use our perfectly assembled date
                    comment: comment.isEmpty ? nil : comment
                )
                try await transactionsService.createTransaction(dto: transactionDTO)
            }
            
            self.shouldDismiss = true
            
        } catch {
            if let networkError = error as? NetworkError {
                errorMessage = networkError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("Failed to save transaction: \(error)")
        }
        
        isLoading = false
    }

    func deleteTransaction() {
        guard let transaction = transaction else {
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await transactionsService.deleteTransaction(byId: transaction.id)
                await MainActor.run {
                    self.shouldDismiss = true
                }
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                print("Failed to delete transaction: \(error)")
                await MainActor.run {
                    self.showingAmountAlert = true
                }
            }
            isLoading = false
        }
    }
}
