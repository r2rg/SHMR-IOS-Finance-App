import Foundation

extension Notification.Name {
    static let accountBalanceChanged = Notification.Name("accountBalanceChanged")
}

@MainActor
final class BankAccountsService {
    static let shared = BankAccountsService()
    let client = NetworkClient()
    let localStorage: SwiftDataBankAccountsStorage
    private let backupStorage: SwiftDataBackupStorage
    var account: BankAccount?
    var isOffline: Bool = false
    var lastCalculatedBalance: Decimal = 0
    private var hasManualBalance: Bool = false
    
    private init() {
        let container = SHMR_Finance_AppApp.sharedModelContainer
        self.localStorage = SwiftDataBankAccountsStorage(container: container)
        self.backupStorage = SwiftDataBackupStorage(container: container)
    }
    
    func getCurrentAccount() -> BankAccount? {
        return account
    }
    
    func syncAccountBackup() async {
        guard !isOffline else { return }
        
        let backupOps = try? await backupStorage.fetchAllBackupOperations()
        let accBackup = backupOps?.filter { $0.entityType == "account" } ?? []
        
        print("Found \(accBackup.count) account backup operations")
        
        if let latestAccountBackup = accBackup.last,
           let backupAccount = try? JSONDecoder().decode(BankAccount.self, from: latestAccountBackup.payload) {
            print("Syncing account backup with balance: \(backupAccount.balance)")
            do {
                let updateDTO = AccountUpdateRequestDTO(from: backupAccount)
                let response: AccountDTO = try await client.request(method: "PUT", url: "accounts/\(backupAccount.id)", body: updateDTO)
                if let updatedAccount = response.toDomain() {
                    account = updatedAccount
                    lastCalculatedBalance = updatedAccount.balance
                    hasManualBalance = false
                    try await localStorage.updateAccount(updatedAccount)
                    
                    let backupIds = accBackup.map { $0.id }
                    try await backupStorage.removeBackupOperations(ids: backupIds, entityType: "account")
                    print("Account backup synced to server, balance: \(updatedAccount.balance)")
                }
            } catch {
                print("Failed to sync account backup: \(error)")
            }
        } else {
            print("No account backup operations found or failed to decode")
        }
    }
    
    func setOfflineMode(_ offline: Bool) {
        let wasOnline = !isOffline
        isOffline = offline

        if !wasOnline && !offline {
            Task {
                do {
                    await syncAccountBackup()
                    
                    let dtos: [AccountDTO] = try await client.request(method: "GET", url: "accounts")
                    if let firstDTO = dtos.first, let first = firstDTO.toDomain() {
                        account = first
                        lastCalculatedBalance = first.balance
                        hasManualBalance = false
                        try await localStorage.updateAccount(first)
                        
                        await MainActor.run {
                            NotificationCenter.default.post(name: .accountBalanceChanged, object: nil)
                        }
                    }
                } catch {
                    print("Failed to sync when going online: \(error)")
                    isOffline = true
                }
            }
        }
    }
    
    func calculateCurrentBalance() async throws -> Decimal {
        guard let currentAccount = account else { 
            throw NSError(domain: "No account available", code: 0)
        }
        
        if !isOffline {
            return currentAccount.balance
        }
        
        let baseBalance = hasManualBalance ? lastCalculatedBalance : currentAccount.balance
        let localChanges = try await calculateLocalBalanceChanges()
        return baseBalance + localChanges
    }
    
    private func calculateLocalBalanceChanges() async throws -> Decimal {
        guard let currentAccount = account else { 
            throw NSError(domain: "No account available", code: 0)
        }
        
        let transactionsStorage = SwiftDataTransactionsStorage(container: SHMR_Finance_AppApp.sharedModelContainer)
        let categoriesStorage = SwiftDataCategoriesStorage(container: SHMR_Finance_AppApp.sharedModelContainer)
        
        let allTransactions = try await transactionsStorage.fetchTransactions(
            accountId: currentAccount.id,
            from: Date.distantPast,
            to: Date.distantFuture
        )
        
        let offlineTransactions = allTransactions.filter { $0.id < 0 }
        let allCategories = try await categoriesStorage.fetchAllCategories()
        
        return offlineTransactions.reduce(Decimal.zero) { sum, transaction in
            guard let category = allCategories.first(where: { $0.id == transaction.categoryId }) else {
                return sum
            }
            
            switch category.direction {
            case .income:
                return sum + transaction.amount
            case .outcome:
                return sum - transaction.amount
            }
        }
    }
    
    func updateBalanceFromTransactions() async throws {
        guard let currentAccount = account else { 
            return 
        }
        
        let newBalance = try await calculateCurrentBalance()
        try await updateBalanceLocally(to: newBalance)
        
        await MainActor.run {
            NotificationCenter.default.post(name: .accountBalanceChanged, object: nil)
        }
    }
    
    func updateBalanceForTransactionChange(oldTransaction: Transaction?, newTransaction: Transaction?, action: TransactionAction) async throws {
        guard let currentAccount = account else { return }
        
        if !isOffline {
            return
        }
        
        let categoriesStorage = SwiftDataCategoriesStorage(container: SHMR_Finance_AppApp.sharedModelContainer)
        let allCategories = try await categoriesStorage.fetchAllCategories()
        
        var balanceChange: Decimal = 0
        
        switch action {
        case .create:
            if let newTx = newTransaction,
               let category = allCategories.first(where: { $0.id == newTx.categoryId }) {
                balanceChange = category.direction == .income ? newTx.amount : -newTx.amount
            }
            
        case .update:
            if let oldTx = oldTransaction,
               let category = allCategories.first(where: { $0.id == oldTx.categoryId }) {
                let oldChange = category.direction == .income ? oldTx.amount : -oldTx.amount
                balanceChange -= oldChange
            }
            
            if let newTx = newTransaction,
               let category = allCategories.first(where: { $0.id == newTx.categoryId }) {
                let newChange = category.direction == .income ? newTx.amount : -newTx.amount
                balanceChange += newChange
            }
            
        case .delete:
            if let oldTx = oldTransaction,
               let category = allCategories.first(where: { $0.id == oldTx.categoryId }) {
                let oldChange = category.direction == .income ? oldTx.amount : -oldTx.amount
                balanceChange -= oldChange
            }
        }
        
        let currentBalance = try await calculateCurrentBalance()
        let newBalance = currentBalance + balanceChange
        
        try await updateBalanceLocally(to: newBalance)
        
        await MainActor.run {
            NotificationCenter.default.post(name: .accountBalanceChanged, object: nil)
        }
    }
    
    enum TransactionAction {
        case create, update, delete
    }
    
    private func updateBalanceLocally(to newBalance: Decimal) async throws {
        guard let account = account else { throw NSError(domain: "No account", code: 0) }
        
        let updatedAccount = BankAccount(
            id: account.id,
            userId: account.userId,
            name: account.name,
            balance: newBalance,
            currency: account.currency,
            createdAt: account.createdAt,
            updatedAt: Date()
        )
        
        self.account = updatedAccount
        self.lastCalculatedBalance = newBalance
        self.hasManualBalance = true
        
        try await localStorage.updateAccount(updatedAccount)
        
        if let data = try? JSONEncoder().encode(updatedAccount) {
            let op = BackupOperationModel(id: updatedAccount.id, actionType: .update, entityType: "account", payload: data, date: Date())
            try await backupStorage.addOrUpdateBackupOperation(op)
        }
    }
    
    func getFirstAccount() async throws -> BankAccount {
        if !isOffline {
            do {
                let dtos: [AccountDTO] = try await client.request(method: "GET", url: "accounts")
                guard let firstDTO = dtos.first, let first = firstDTO.toDomain() else {
                    throw NSError(domain: "Invalid account", code: 0)
                }
                account = first
                lastCalculatedBalance = first.balance
                hasManualBalance = false
                try await localStorage.createAccount(first)
                return first
            } catch {
                isOffline = true
            }
        }
        
        let localAccounts = try await localStorage.fetchAllAccounts()
        let backup = try await backupStorage.fetchAllBackupOperations()
            .filter { $0.entityType == "account" }
            .compactMap { try? JSONDecoder().decode(BankAccount.self, from: $0.payload) }
        
        if let backupAcc = backup.first { 
            account = backupAcc
            lastCalculatedBalance = backupAcc.balance
            hasManualBalance = true
            return backupAcc 
        }
        if let localAcc = localAccounts.first { 
            account = localAcc
            lastCalculatedBalance = localAcc.balance
            hasManualBalance = false
            return localAcc 
        }
        throw NSError(domain: "No account available", code: 0)
    }
    
    func changeBalance(to newBalance: Decimal) async throws {
        guard let account = account else { throw NSError(domain: "No account", code: 0) }
        
        if isOffline {
            throw NSError(domain: "Cannot change balance while offline", code: 0, userInfo: [NSLocalizedDescriptionKey: "Balance can only be changed when online"])
        }
        
        let updatedAccount = BankAccount(
            id: account.id,
            userId: account.userId,
            name: account.name,
            balance: newBalance,
            currency: account.currency,
            createdAt: account.createdAt,
            updatedAt: Date()
        )
        
        let updateDTO = AccountUpdateRequestDTO(from: updatedAccount)
        do {
            let changedDTO: AccountDTO = try await client.request(method: "PUT", url: "accounts/\(account.id)", body: updateDTO)
            guard let changedAccount = changedDTO.toDomain() else {
                throw NSError(domain: "Invalid response", code: 0)
            }
            self.account = changedAccount
            self.lastCalculatedBalance = changedAccount.balance
            self.hasManualBalance = false
            try await localStorage.updateAccount(changedAccount)
            
            await MainActor.run {
                NotificationCenter.default.post(name: .accountBalanceChanged, object: nil)
            }
        } catch {
            throw error
        }
    }
    
    func changeCurrency(to newCurrency: String) async throws {
        guard let account = account else { throw NSError(domain: "No account", code: 0) }
        let id = account.id
        var updatedAccount = account
        updatedAccount = BankAccount(
            id: account.id,
            userId: account.userId,
            name: account.name,
            balance: account.balance,
            currency: newCurrency,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt
        )
        let updateDTO = AccountUpdateRequestDTO(from: updatedAccount)
        do {
            let changedDTO: AccountDTO = try await client.request(method: "PUT", url: "accounts/\(id)", body: updateDTO)
            guard let changedAccount = changedDTO.toDomain() else {
                throw NSError(domain: "Invalid response", code: 0)
            }
            self.account = changedAccount
            try await localStorage.updateAccount(changedAccount)
            try await backupStorage.removeBackupOperation(id: changedAccount.id, entityType: "account")
        } catch {
            if let data = try? JSONEncoder().encode(updatedAccount) {
                let op = BackupOperationModel(id: updatedAccount.id, actionType: .update, entityType: "account", payload: data, date: Date())
                try await backupStorage.addOrUpdateBackupOperation(op)
                self.account = updatedAccount
            }
            throw error
        }
    }
}

