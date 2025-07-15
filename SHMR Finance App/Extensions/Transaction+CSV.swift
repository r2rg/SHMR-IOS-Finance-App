//
//  Transaction+CSV.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 15.07.2025.
//

import SwiftUI

// DateFormatter для конвертации между Date и String.
private let apiDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

extension Transaction {
    // Парсинг строки CSV
    static func parse(csvRow: String) -> Transaction? {
        let columns = csvRow.components(separatedBy: ",")
        
        guard columns.count == 8 else {
            print("Ошибка парсинга CSV: неверное количество столбцов. Ожидалось 8, получено \(columns.count).")
            return nil
        }
        
        guard
            let id = Int(columns[0]),
            let accountId = Int(columns[1]),
            let categoryId = Int(columns[2]),
            let amount = Decimal(string: columns[3]),
            let transactionDate = apiDateFormatter.date(from: columns[4]),
            // Столбец с комментарием (index 5) мы обработаем отдельно.
            let createdAt = apiDateFormatter.date(from: columns[6]),
            let updatedAt = apiDateFormatter.date(from: columns[7])
        else {
            print("Ошибка парсинга CSV: не удалось преобразовать одно или несколько значений в строке.")
            return nil
        }
        
        let comment = columns[5].isEmpty ? nil : columns[5]
        
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // Парсинг CSV построчно
    static func parse(csvString: String) -> [Transaction] {
        let rows = csvString.components(separatedBy: .newlines)
        
        let transactions = rows.compactMap { row in
            return Transaction.parse(csvRow: row)
        }
        
        return transactions
    }
}
