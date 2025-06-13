import Foundation

struct Transaction {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
}

// DateFormatter для конвертации между Date и String.
private let apiDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

extension Transaction {
    
    var jsonObject: Any {
        var dictionary: [String: Any] = [
            "id": self.id,
            "accountId": self.accountId,
            "categoryId": self.categoryId,
            "amount": "\(self.amount)",
            "transactionDate": apiDateFormatter.string(from: self.transactionDate),
            "createdAt": apiDateFormatter.string(from: self.createdAt),
            "updatedAt": apiDateFormatter.string(from: self.updatedAt)
        ]
        
        if let comment = self.comment {
            dictionary["comment"] = comment
        }
        
        return dictionary
    }
    
    static func parse(jsonObject: Any) -> Transaction? {
        guard let dictionary = jsonObject as? [String: Any] else {
            return nil
        }
        
        guard
            let id = dictionary["id"] as? Int,
            let accountId = dictionary["accountId"] as? Int,
            let categoryId = dictionary["categoryId"] as? Int,
            
                let amountString = dictionary["amount"] as? String,
            let amount = Decimal(string: amountString),
            
                let transactionDateString = dictionary["transactionDate"] as? String,
            let createdAtString = dictionary["createdAt"] as? String,
            let updatedAtString = dictionary["updatedAt"] as? String,
            
                let transactionDate = apiDateFormatter.date(from: transactionDateString),
            let createdAt = apiDateFormatter.date(from: createdAtString),
            let updatedAt = apiDateFormatter.date(from: updatedAtString)
        else {
            return nil
        }
        
        // Необязательное поле, поэтому получаем его отдельно.
        let comment = dictionary["comment"] as? String
        
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
