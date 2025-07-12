//
//  TransactionEditView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 12.07.2025.
//

import SwiftUI

struct TransactionEditView: View {
    let mode: EditMode
    let direction: Direction
    let transaction: Transaction?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: Category?
    @State private var amount: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var comment: String = ""
    @State private var showingCategoryPicker = false
    @State private var showingAmountAlert = false
    @State private var showingValidationAlert = false
    @State private var categories: [Category] = []
    @State private var account: BankAccount?
    
    private let transactionsService = TransactionsService.shared
    private let categoriesService = CategoriesService.shared
    private let bankAccountsService = BankAccountsService.shared
    
    init(mode: EditMode, direction: Direction, transaction: Transaction? = nil) {
        self.mode = mode
        self.direction = direction
        self.transaction = transaction
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        LabeledContent("Статья") {
                            HStack {
                                if let category = selectedCategory {
                                    Text(category.name)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Выберите статью")
                                        .foregroundStyle(.gray)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    LabeledContent("Сумма") {
                        HStack {
                            TextField("0", text: $amount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: amount) { oldValue, newValue in
                                    amount = formatAmount(newValue)
                                }
                            if let account = account {
                                Text(account.currency)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    LabeledContent("Дата") {
                        CustomDatePickerView(selectedDate: $selectedDate)
                            .onChange(of: selectedDate) { oldValue, newValue in
                                if newValue > Date() {
                                    selectedDate = Date()
                                }
                            }
                    }
                    
                    LabeledContent("Время") {
                        CustomTimePickerView(selectedTime: $selectedTime)
                    }
                    
                    TextField("Комментарий", text: $comment)
                        .textFieldStyle(.plain)
                }
                
                if mode == .edit {
                    Section {
                        Button("Удалить \(direction == .outcome ? "расход" : "доход")") {
                            deleteTransaction()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .safeAreaPadding(.top)
            .navigationTitle(mode == .edit ? "Мои \(direction == .outcome ? "расходы" : "доходы")" : "Новый \(direction == .outcome ? "расход" : "доход")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(mode == .edit ? "Сохранить" : "Создать") {
                        saveTransaction()
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    direction: direction
                )
            }
            .alert("Ошибка", isPresented: $showingAmountAlert) {
                Button("OK") { }
            } message: {
                Text("Пожалуйста, введите корректную сумму")
            }
            .alert("Заполните все поля", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text("Пожалуйста, заполните все обязательные поля")
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
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
    
    private func saveTransaction() {
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
                    dismiss()
                }
            } catch {
                print("Failed to save transaction: \(error)")
                await MainActor.run {
                    showingAmountAlert = true
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
    
    private func deleteTransaction() {
        guard let transaction = transaction else { 
            return 
        }
        
        Task {
            do {
                try await transactionsService.deleteTransaction(byId: transaction.id)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to delete transaction: \(error)")
                await MainActor.run {
                    showingAmountAlert = true
                }
            }
        }
    }
}

enum EditMode {
    case create
    case edit
}

struct CategoryPickerView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    let direction: Direction
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    Button(action: {
                        selectedCategory = category
                        dismiss()
                    }) {
                        HStack {
                            Text(category.name)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Выберите статью")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TransactionEditView(mode: .create, direction: .outcome)
}
