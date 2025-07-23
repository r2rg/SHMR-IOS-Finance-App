import Foundation

// Сервис подлежит пределыванию
@MainActor
final class TransactionsService {
    static let shared = TransactionsService()
    let client = NetworkClient()
    private let localStorage: SwiftDataTransactionsStorage
    private let backupStorage: SwiftDataBackupStorage
    private let bankAccountsService = BankAccountsService.shared
    
    private init() {
        let container = SHMR_Finance_AppApp.sharedModelContainer
        self.localStorage = SwiftDataTransactionsStorage(container: container)
        self.backupStorage = SwiftDataBackupStorage(container: container)
    }

    private func updateAccountBalance() async {
        do {
            if !bankAccountsService.isOffline {
                let dtos: [AccountDTO] = try await client.request(method: "GET", url: "accounts")
                if let firstDTO = dtos.first, let first = firstDTO.toDomain() {
                    bankAccountsService.account = first
                    bankAccountsService.lastCalculatedBalance = first.balance
                    try await bankAccountsService.localStorage.updateAccount(first)
                    
                    await MainActor.run {
                        NotificationCenter.default.post(name: .accountBalanceChanged, object: nil)
                    }
                }
            } else {
                try await bankAccountsService.updateBalanceFromTransactions()
            }
        } catch {
            print("Failed to update account balance: \(error)")
        }
    }

    func getTransactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let backupOps = try await backupStorage.fetchAllBackupOperations()
        let txBackup = backupOps.filter { $0.entityType == "transaction" }
        var syncedIds: [Int] = []
        for op in txBackup {
            do {
                let transaction = try JSONDecoder().decode(Transaction.self, from: op.payload)
                switch op.actionType {
                case "create":
                    let dto = TransactionRequestDTO(from: transaction)
                    let response: TransactionDTO = try await client.request(method: "POST", url: "transactions", body: dto)
                    // Обновляем локальное хранилище с правильным ID от сервера
                    if let updatedTx = dto.toDomain(id: response.id) {
                        try await localStorage.createTransaction(updatedTx)
                    }
                case "update":
                    let dto = TransactionRequestDTO(from: transaction)
                    _ = try await client.request(method: "PUT", url: "transactions/\(transaction.id)", body: dto)
                    try await localStorage.updateTransaction(transaction)
                case "delete":
                    _ = try await client.request(method: "DELETE", url: "transactions/\(transaction.id)")
                    try await localStorage.deleteTransaction(id: transaction.id)
                default: break
                }
                syncedIds.append(op.id)
            } catch {
            }
        }

        try await backupStorage.removeBackupOperations(ids: syncedIds, entityType: "transaction")
        
        try? await bankAccountsService.syncAccountBackup()
        
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            let url = "transactions/account/\(accountId)/period?startDate=\(start)&endDate=\(end)"
            let dtos: [TransactionResponseDTO] = try await client.request(method: "GET", url: url)
            let transactions = dtos.compactMap { $0.toDomain() }

            let existingTransactions = try await localStorage.fetchTransactions(accountId: accountId, from: startDate, to: endDate)
            for tx in existingTransactions {
                try await localStorage.deleteTransaction(id: tx.id)
            }

            for tx in transactions {
                try await localStorage.createTransaction(tx)
            }
            
            return transactions
        } catch {

            let local = try await localStorage.fetchTransactions(accountId: accountId, from: startDate, to: endDate)
            let backupOps = try await backupStorage.fetchAllBackupOperations()
                .filter { $0.entityType == "transaction" }

            var mergedDict: [Int: Transaction] = [:]
            var deletedIds: Set<Int> = []
            
            for tx in local {
                mergedDict[tx.id] = tx
            }
            
            for op in backupOps {
                switch op.actionType {
                case "create", "update":
                    if let tx = try? JSONDecoder().decode(Transaction.self, from: op.payload),
                       tx.accountId == accountId && tx.transactionDate >= startDate && tx.transactionDate <= endDate {
                        mergedDict[tx.id] = tx
                    }
                case "delete":
                    deletedIds.insert(op.id)
                default:
                    break
                }
            }
            
            for deletedId in deletedIds {
                mergedDict.removeValue(forKey: deletedId)
            }
            
            let merged = mergedDict.values.sorted { $0.transactionDate > $1.transactionDate }
            return Array(merged)
        }
    }

    func createTransaction(dto transactionDTO: TransactionRequestDTO) async throws {
        do {
            let response: TransactionDTO = try await client.request(method: "POST", url: "transactions", body: transactionDTO)
            if let tx = transactionDTO.toDomain(id: response.id) {
                try await localStorage.createTransaction(tx)
                try await backupStorage.removeBackupOperation(id: tx.id, entityType: "transaction")
                // Обновляем баланс после успешного создания
                await updateAccountBalance()
            }
        } catch {
            let tempId = Int(Date().timeIntervalSince1970 * 1000) * -1
            if let tx = transactionDTO.toDomain(id: tempId), let data = try? JSONEncoder().encode(tx) {
                let op = BackupOperationModel(id: tx.id, actionType: .create, entityType: "transaction", payload: data, date: Date())
                try await backupStorage.addOrUpdateBackupOperation(op)
                
                if bankAccountsService.isOffline {
                    try await bankAccountsService.updateBalanceForTransactionChange(
                        oldTransaction: nil,
                        newTransaction: tx,
                        action: BankAccountsService.TransactionAction.create
                    )
                }
            }
            throw error
        }
    }

    func editTransaction(_ transaction: Transaction) async throws {
        let oldTransaction = try? await localStorage.fetchTransaction(id: transaction.id)
        
        do {
            let dto = TransactionRequestDTO(from: transaction)
            _ = try await client.request(method: "PUT", url: "transactions/\(transaction.id)", body: dto)
            try await localStorage.updateTransaction(transaction)
            try await backupStorage.removeBackupOperation(id: transaction.id, entityType: "transaction")
            await updateAccountBalance()
        } catch {
            if let data = try? JSONEncoder().encode(transaction) {
                let op = BackupOperationModel(id: transaction.id, actionType: .update, entityType: "transaction", payload: data, date: Date())
                try await backupStorage.addOrUpdateBackupOperation(op)
                
                if bankAccountsService.isOffline {
                    try await bankAccountsService.updateBalanceForTransactionChange(
                        oldTransaction: oldTransaction,
                        newTransaction: transaction,
                        action: BankAccountsService.TransactionAction.update
                    )
                }
            }
            throw error
        }
    }

    func deleteTransaction(byId id: Int) async throws {
        let transactionToDelete = try? await localStorage.fetchTransaction(id: id)
        
        do {
            _ = try await client.request(method: "DELETE", url: "transactions/\(id)")
            try await localStorage.deleteTransaction(id: id)
            try await backupStorage.removeBackupOperation(id: id, entityType: "transaction")
            await updateAccountBalance()
        } catch {
            try await localStorage.deleteTransaction(id: id)

            if let deletedTransaction = transactionToDelete, let data = try? JSONEncoder().encode(deletedTransaction) {
                let op = BackupOperationModel(id: id, actionType: .delete, entityType: "transaction", payload: data, date: Date())
                try await backupStorage.addOrUpdateBackupOperation(op)
            }

            if let deletedTransaction = transactionToDelete, bankAccountsService.isOffline {
                try await bankAccountsService.updateBalanceForTransactionChange(
                    oldTransaction: deletedTransaction,
                    newTransaction: nil,
                    action: BankAccountsService.TransactionAction.delete
                )
            }
            
            throw error
        }
    }
}
