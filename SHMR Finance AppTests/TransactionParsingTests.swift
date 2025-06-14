import Testing
@testable import SHMR_Finance_App
import Foundation

struct TransactionParsingTests {

    private let apiDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // Тесты для `jsonObject` (Transaction -> Dictionary)

    @Test("jsonObject: Корректно создает словарь из валидной транзакции")
    func jsonObject_createsCorrectDictionary() throws {
        let date = Date()
        let transaction = Transaction(
            id: 101, accountId: 1, categoryId: 2, amount: Decimal(string: "19.99")!,
            transactionDate: date, comment: "Тестовый комментарий",
            createdAt: date, updatedAt: date
        )

        let result = transaction.jsonObject

        let dictionary = try #require(result as? [String: Any])

        #expect(dictionary["id"] as? Int == 101)
        #expect(dictionary["accountId"] as? Int == 1)
        #expect(dictionary["categoryId"] as? Int == 2)
        #expect(dictionary["amount"] as? String == "19.99")
        #expect(dictionary["comment"] as? String == "Тестовый комментарий")
        #expect(dictionary["transactionDate"] as? String == apiDateFormatter.string(from: date))
    }

    @Test("jsonObject: Не добавляет ключ 'comment', если комментарий nil")
    func jsonObject_omitsNilComment() throws {
        let transaction = Transaction(
            id: 102, accountId: 1, categoryId: 3, amount: 100,
            transactionDate: Date(), comment: nil,
            createdAt: Date(), updatedAt: Date()
        )
        
        let dictionary = try #require(transaction.jsonObject as? [String: Any])
        
        #expect(dictionary["comment"] == nil)
    }
    
    // Тесты для `parse(jsonObject:)` (Dictionary -> Transaction)
    
    @Test("parse(jsonObject): Корректно создает транзакцию из валидного словаря")
    func parse_createsCorrectTransaction() throws {
        let date = Date()
        let dateString = apiDateFormatter.string(from: date)
        let validDictionary: [String: Any] = [
            "id": 201, "accountId": 10, "categoryId": 20, "amount": "123.45",
            "transactionDate": dateString, "comment": "Успешный парсинг",
            "createdAt": dateString, "updatedAt": dateString
        ]
        
        let transaction = try #require(Transaction.parse(jsonObject: validDictionary))
        
        #expect(transaction.id == 201)
        #expect(transaction.amount == Decimal(string: "123.45"))
        #expect(transaction.comment == "Успешный парсинг")
        
        let dateDifference = abs(transaction.transactionDate.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate)
        #expect(dateDifference < 0.001)
    }

    @Test("parse(jsonObject): Возвращает nil при отсутствии обязательного поля")
    func parse_returnsNilForMissingKey() {
        let invalidDictionary: [String: Any] = [
            "id": 202,
            "transactionDate": apiDateFormatter.string(from: Date())
        ]
        
        let transaction = Transaction.parse(jsonObject: invalidDictionary)

        #expect(transaction == nil, "Парсинг должен вернуть nil, если отсутствует обязательное поле")
    }
    
    @Test("parse(jsonObject): Возвращает nil при неверном типе данных")
    func parse_returnsNilForWrongDataType() {
        let invalidDictionary: [String: Any] = [
            "id": "не-число", "accountId": 1, "categoryId": 1, "amount": "100",
            "transactionDate": "не-дата", "createdAt": "не-дата", "updatedAt": "не-дата"
        ]
        
        let transaction = Transaction.parse(jsonObject: invalidDictionary)

        #expect(transaction == nil, "Парсинг должен вернуть nil, если тип данных неверный")
    }

    @Test("parse(jsonObject): Создает транзакцию с nil-комментарием, если ключ отсутствует")
    func parse_handlesMissingOptionalComment() throws {
        let dateString = apiDateFormatter.string(from: Date())
        let dictionaryWithoutComment: [String: Any] = [
            "id": 203, "accountId": 1, "categoryId": 1, "amount": "50.0",
            "transactionDate": dateString, "createdAt": dateString, "updatedAt": dateString
        ]
        
        let transaction = try #require(Transaction.parse(jsonObject: dictionaryWithoutComment))
        
        #expect(transaction.comment == nil, "Комментарий должен быть nil, если ключ отсутствует в JSON")
    }
}
