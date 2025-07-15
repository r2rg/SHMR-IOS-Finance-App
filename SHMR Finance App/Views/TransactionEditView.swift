//
//  TransactionEditView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 12.07.2025.
//

import SwiftUI

struct TransactionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: TransactionEditViewModel

    init(mode: EditMode, direction: Direction, transaction: Transaction? = nil) {
        _viewModel = State(wrappedValue: TransactionEditViewModel(mode: mode, direction: direction, transaction: transaction))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        viewModel.showingCategoryPicker = true
                    }) {
                        LabeledContent("Статья") {
                            HStack {
                                if let category = viewModel.selectedCategory {
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
                            TextField("0", text: $viewModel.amount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: viewModel.amount) { oldValue, newValue in
                                    viewModel.amount = viewModel.formatAmount(newValue)
                                }
                            if let account = viewModel.account {
                                Text(account.currency)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    LabeledContent("Дата") {
                        CustomDatePickerView(selectedDate: $viewModel.selectedDate)
                            .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                                if newValue > Date() {
                                    viewModel.selectedDate = Date()
                                }
                            }
                    }

                    LabeledContent("Время") {
                        CustomTimePickerView(selectedTime: $viewModel.selectedTime)
                    }

                    TextField("Комментарий", text: $viewModel.comment)
                        .textFieldStyle(.plain)
                }

                if viewModel.mode == .edit {
                    Section {
                        Button("Удалить \(viewModel.direction == .outcome ? "расход" : "доход")") {
                            viewModel.deleteTransaction()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .safeAreaPadding(.top)
            .navigationTitle(viewModel.mode == .edit ? "Мои \(viewModel.direction == .outcome ? "расходы" : "доходы")" : "Новый \(viewModel.direction == .outcome ? "расход" : "доход")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.mode == .edit ? "Сохранить" : "Создать") {
                        viewModel.saveTransaction()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCategoryPicker) {
                CategoryPickerView(
                    categories: viewModel.categories,
                    selectedCategory: $viewModel.selectedCategory,
                    direction: viewModel.direction
                )
            }
            .alert("Ошибка", isPresented: $viewModel.showingAmountAlert) {
                Button("OK") { }
            } message: {
                Text("Пожалуйста, введите корректную сумму")
            }
            .alert("Заполните все поля", isPresented: $viewModel.showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text("Пожалуйста, заполните все обязательные поля")
            }
            .task {
                await viewModel.loadData()
            }
            .onChange(of: viewModel.shouldDismiss) { _, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

enum EditMode {
    case create
    case edit
}


#Preview {
    TransactionEditView(mode: .create, direction: .outcome)
}
