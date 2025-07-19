//
//  AccountViewModel.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 15.07.2025.
//

import SwiftUI

extension AccountView {
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
        var isLoading: Bool = false
        var errorMessage: String? = nil
        
        func processedBalance() -> String {
            return formattedBalanceString(for: account?.balance) + " " + (account?.currency ?? "")
        }
        
        func fetchAccount() async {
            isLoading = true
            errorMessage = nil
            do {
                account = try await bankAccountService.getFirstAccount()
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
            return formatter.string(from: balance as NSDecimalNumber) ?? ""
        }

        
        // Тут проверка ввода. Когда что-то вставляется из буфера обмена и сохраняется, все лишние символы будут отфильтрованы
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
            if localeSeparator == "," {
                return filtered.replacingOccurrences(of: ".", with: ",")
            } else {
                return filtered.replacingOccurrences(of: ",", with: ".")
            }
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
