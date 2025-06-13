import Foundation

final class TransactionsFileCache {
    private(set) var transactions: [Transaction] = []
    
    private let fileURL: URL

    // Инициализатор класса. Принимает имя файла, чтобы можно было создавать несколько разных кэшей.
    init(filename: String = "transactions.json") {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = baseURL.appendingPathComponent(filename)
        
        load()
    }

    func add(_ transaction: Transaction) {
        // Проверяем, существует ли уже транзакция с таким же id.
        if !transactions.contains(where: { $0.id == transaction.id }) {
            transactions.append(transaction)
        }
    }

    func remove(byId id: Int) {
        transactions.removeAll(where: { $0.id == id })
    }

    func save() {
        do {
            let jsonArray = transactions.map { $0.jsonObject }
            
            let data = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            
            try data.write(to: fileURL)
            print("Транзакции успешно сохранены в файл: \(fileURL.path)")
        } catch {
            print("Ошибка при сохранении транзакций: \(error.localizedDescription)")
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Файл не найден, начинаем с пустого списка транзакций.")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonArray = jsonObject as? [[String: Any]] else {
                print("Ошибка: JSON не является массивом словарей.")
                self.transactions = []
                return
            }
            
            self.transactions = jsonArray.compactMap { Transaction.parse(jsonObject: $0) }
            print("Успешно загружено \(transactions.count) транзакций.")

        } catch {
            print("Ошибка при загрузке транзакций: \(error.localizedDescription)")
            self.transactions = []
        }
    }
}
