//
//  Untitled.swift
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
}
