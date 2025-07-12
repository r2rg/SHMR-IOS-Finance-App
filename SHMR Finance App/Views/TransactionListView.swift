//
//  TransactionsListView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 18.06.2025.
//

import SwiftUI

struct TransactionListView: View {
    let direction: Direction
    
    @State private var viewModel = TransactionItemViewModel()
    @State private var showingCreateTransaction = false
    @State private var selectedTransaction: Transaction?
    
    var body: some View {
        let title = (direction == .outcome ? "Расходы" : "Доходы") + " сегодня"
        NavigationStack {
            List {
                LabeledContent {
                    Text("\(viewModel.getSum()) " + viewModel.currency)
                        .foregroundStyle(.primary)
                } label: {
                    Text("Всего")
                }
                
                Section("Операции") {
                    ForEach(viewModel.displayedTransactions) { transaction in
                        TransactionView(transaction: transaction, direction: direction, currency: viewModel.currency)
                            .padding(.vertical, -5)
                            .onTapGesture {
                                selectedTransaction = transaction.transaction
                            }
                    }
                }
            }
            .navigationTitle(title)
            .safeAreaPadding(.top)
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    showingCreateTransaction = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 25))
                        .foregroundStyle(.white)
                        .frame(width: 65.0, height: 65.0)
                        .background(.accent)
                        .clipShape(Circle())
                }
                .padding(.horizontal)
                .padding(.bottom, 27)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: TransactionHistoryView(direction: direction)) {
                        Image(systemName: "clock")
                    }
                }
            }
            .task {
                Task {
                    do {
                        try await viewModel.loadTodaysTransactions(for: direction)
                    } catch {
                        print("Failed to fetch.")
                    }
                }
            }
            .task {
                await viewModel.getCurrency()
            }
            .sheet(isPresented: $showingCreateTransaction) {
                TransactionEditView(mode: .create, direction: direction)
                    .onDisappear {
                        Task {
                            try? await viewModel.loadTodaysTransactions(for: direction)
                        }
                    }
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionEditView(mode: .edit, direction: direction, transaction: transaction)
                    .onDisappear {
                        Task {
                            try? await viewModel.loadTodaysTransactions(for: direction)
                        }
                    }
            }
        }
        .tint(.purple)
    }
}

#Preview {
    TransactionListView(direction: .outcome)
}
