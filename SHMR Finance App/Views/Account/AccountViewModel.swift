//
//  AccountViewModel.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 15.07.2025.
//
import SwiftUI

extension AccountView {
    struct DailyBalance: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        var balance: Decimal
    }
    
    @Observable
    class ViewModel {
        var editing = false
        var isPresentingCurrencyPicker = false
        var isBalanceSpoiled = true
        
        var account: BankAccount?
        var previousBalanceText: String = ""
        var balanceText: String = "" {
            didSet {
                let sanitized = sanitize(decimalString: balanceText)
                let separator = Locale.current.decimalSeparator ?? "."
                if let sepRange = sanitized.range(of: separator) {
                    let fractionalPart = sanitized[sepRange.upperBound...]
                    if fractionalPart.count > 2 {
                        balanceText = previousBalanceText
                        return
                    }
                }
            }
        }

        var bankAccountService = BankAccountsService.shared
        private var transactionsService = TransactionsService.shared
        private var categoriesService = CategoriesService.shared
        
        var isLoading: Bool = false
        var errorMessage: String? = nil
        
        var dailyBalances: [DailyBalance] = []
        var selectedBalanceData: DailyBalance?
        
        
        // --- ЛОГИКА ПОЛНОСТЬЮ ПЕРЕРАБОТАНА ---
        func calculateBalanceHistory() async {
            guard let account = account else { return }

            let calendar = Calendar.current
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) else { return }

            do {
                let transactions = try await transactionsService.getTransactions(accountId: account.id, from: startDate, to: endDate)
                let categories = try await categoriesService.allCategories()
                
                let categoryDirections = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.direction) })
                
                var dailyNetChange = [Date: Decimal]()
                for transaction in transactions {
                    let day = calendar.startOfDay(for: transaction.transactionDate)
                    
                    if let direction = categoryDirections[transaction.categoryId] {
                        let signedAmount = (direction == .outcome) ? -transaction.amount : transaction.amount
                        dailyNetChange[day, default: 0] += signedAmount
                    } else {
                        print("Warning: Category with ID \(transaction.categoryId) not found.")
                    }
                }

                var finalBalances = [DailyBalance]()
                var runningBalance = account.balance
                
                for i in 0..<30 {
                    let day = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -i, to: endDate)!)
                    
                    if i > 0 {
                        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
                        runningBalance -= dailyNetChange[nextDay] ?? 0
                    }
                    
                    finalBalances.append(DailyBalance(date: day, balance: runningBalance))
                }
                
                self.dailyBalances = finalBalances.reversed()
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Не удалось загрузить историю транзакций: \(error.localizedDescription)"
                }
            }
        }
        
        func showPopover(for data: DailyBalance) {
            self.selectedBalanceData = data
        }
        
        func processedBalance() -> String {
            return formattedBalanceString(for: account?.balance) + " " + (account?.currency ?? "")
        }
        
        func fetchAccount() async {
            isLoading = true
            errorMessage = nil
            do {
                account = try await bankAccountService.getFirstAccount()
                await calculateBalanceHistory()
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
        
        @MainActor func refreshAccountFromCache() {
            Task {
                do {
                    let currentBalance = try await bankAccountService.calculateCurrentBalance()
                    if let currentAccount = bankAccountService.getCurrentAccount() {
                        let updatedAccount = BankAccount(
                            id: currentAccount.id,
                            userId: currentAccount.userId,
                            name: currentAccount.name,
                            balance: currentBalance,
                            currency: currentAccount.currency,
                            createdAt: currentAccount.createdAt,
                            updatedAt: Date()
                        )
                        account = updatedAccount
                        await calculateBalanceHistory()
                    }
                } catch {
                    print("Error refreshing account balance: \(error)")
                }
            }
        }
        
        func formattedBalanceString(for balance: Decimal?) -> String {
            guard let balance = balance else { return "0.00" }
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return (formatter.string(from: balance as NSDecimalNumber) ?? "") + " " + (account?.currency ?? "")
        }
        
        func sanitize(decimalString: String) -> String {
            var hasFoundSeparator = false
            let filtered = decimalString.filter { char in
                if char.isNumber { return true }
                if (char == "." || char == ",") && !hasFoundSeparator {
                    hasFoundSeparator = true
                    return true
                }
                return false
            }
            let localeSeparator = Locale.current.decimalSeparator ?? "."
            return localeSeparator == "," ? filtered.replacingOccurrences(of: ".", with: ",") : filtered.replacingOccurrences(of: ",", with: ".")
        }
        
        func sanitizedBalance() {
            if editing {
                let sanitizedText = sanitize(decimalString: balanceText)
                let formatter = NumberFormatter()
                formatter.locale = Locale.current
                if let number = formatter.number(from: sanitizedText) {
                    let decimalValue = number.decimalValue
                    updateBalance(to: decimalValue)
                }
            } else {
                balanceText = "\(account?.balance ?? 0)"
            }
        }
        
        func updateBalance(to newBalance: Decimal) {
            Task {
                do {
                    try await bankAccountService.changeBalance(to: newBalance)
                    await fetchAccount()
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        
        func updateCurrency(to newCurrency: String) {
            Task {
                do {
                    guard account != nil else { return }
                    try await bankAccountService.changeCurrency(to: newCurrency)
                    await fetchAccount()
                } catch {
                    print("Error updating currency: \(error)")
                }
            }
        }
    }
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}
