//
//  TransactionHistoryView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 20.06.2025.
//

import SwiftUI

struct TransactionHistoryView: View {

    @State private var viewModel = TransactionItemViewModel()
    @State private var selectedTransaction: Transaction?
    
    let direction: Direction
    
    var body: some View {
        NavigationStack{
            List {
                LabeledContent {
                    CustomDatePickerView(selectedDate: $viewModel.startDate)
                        .tint(.accent)
                } label: {
                    Text("Начало")
                }
                .padding(.vertical, -5)
                LabeledContent {
                    CustomDatePickerView(selectedDate: $viewModel.endDate)
                        .tint(.accent)
                } label: {
                    Text("Конец")
                }
                .padding(.vertical, -5)
                
                Picker("Сортировка", selection: $viewModel.selectedSort) {
                    ForEach(SortCriteria.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .tint(.accent)
                .padding(.vertical, -3)

                LabeledContent {
                    Text("\(viewModel.getSum()) " + "\(viewModel.currency)")
                } label: {
                    Text("Сумма")
                }
                .foregroundStyle(.primary)
                
                Section("Операции") {
                    ForEach(viewModel.displayedTransactions) { transaction in
                        TransactionView(transaction: transaction, direction: direction, currency: viewModel.currency)
                            .padding(.vertical, -3)
                            .onTapGesture {
                                selectedTransaction = transaction.transaction
                            }
                    }
                }
            }
            .navigationTitle("Моя история")
            .toolbar {
                NavigationLink(destination: AnalysisViewScreen(direction: direction)) {
                    Image(systemName: "document")
                }
            }
            .task {
                do {
                    try await viewModel.loadTransactions(for: direction)
                } catch {
                    print("Failed to load: \(error)")
                }
            }
            .task {
                await viewModel.getCurrency()
            }
            .onChange(of: viewModel.startDate) { oldValue, newValue in
                //viewModel.startDateChanged(startDate)
                if newValue > viewModel.endDate {
                    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: newValue)!
                    viewModel.endDate = Calendar.current.date(byAdding: .second, value: -1, to: nextDay)!
                }
                Task {
                   try await viewModel.loadTransactions(for: direction)
                }
            }
            .onChange(of: viewModel.endDate) { oldValue, newValue in
                if newValue < viewModel.startDate {
                    viewModel.startDate = Calendar.current.startOfDay(for: newValue)
                }
                Task {
                   try await viewModel.loadTransactions(for: direction)
                }
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionEditView(mode: .edit, direction: direction, transaction: transaction)
                    .onDisappear {
                        Task {
                            try? await viewModel.loadTransactions(for: direction)
                        }
                    }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}

#Preview {
    TransactionHistoryView(direction: .outcome)
}
