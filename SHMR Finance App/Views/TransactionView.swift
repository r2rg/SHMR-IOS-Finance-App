//
//  TransactionView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 20.06.2025.
//

import SwiftUI

struct TransactionView: View {
    let transaction: TransactionViewItem
    let direction: Direction
    let currency: String
    
    var body: some View {
        LabeledContent {
            Text("\(transaction.transaction.amount)" + " \(currency)")
                .foregroundStyle(.primary)
        } label: {
            Label {
                VStack {
                    Text("\(transaction.category.name)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let comment = transaction.transaction.comment {
                        Text(comment)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } icon: {
                if direction == .outcome {
                    ZStack {
                        Circle()
                            .foregroundStyle(Color.lightGreen)
                        Text("\(transaction.category.emoji)")
                            .font(.system(size: 14))
                    }
                }
            }
        }
    }
}

#Preview {
    let dummyTransaction = Transaction(
        id: 101,
        accountId: 1,
        categoryId: 2,
        amount: Decimal(string: "750.50")!,
        transactionDate: Date(),
        comment: "Покупка в супермаркете",
        createdAt: Date(),
        updatedAt: Date()
    )
    let dummyCategory = Category(id: 1, name: "Test", emoji: "🌍", direction: .outcome)
    let currency = "₽"
    let dummyTransactionViewItem = TransactionViewItem(id: 1, transaction: dummyTransaction, category: dummyCategory)
    
    TransactionView(transaction: dummyTransactionViewItem, direction: .outcome, currency: currency)
}
