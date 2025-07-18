import Foundation

final class BankAccountsService {
    static let shared = BankAccountsService()
    let client = NetworkClient()
    private var account: BankAccount?
    
    private init() {}
    
    func getFirstAccount() async throws -> BankAccount {
        let dtos: [AccountDTO] = try await client.request(method: "GET", url: "accounts")
        guard let firstDTO = dtos.first, let first = firstDTO.toDomain() else {
            throw NSError(domain: "Invalid account", code: 0)
        }
        account = first
        return first
    }
    
    func changeBalance(to newBalance: Decimal) async throws {
        guard let account = account else { throw NSError(domain: "No account", code: 0) }
        let id = account.id
        var updatedAccount = account
        updatedAccount = BankAccount(
            id: account.id,
            userId: account.userId,
            name: account.name,
            balance: newBalance,
            currency: account.currency,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt
        )
        let updateDTO = AccountUpdateRequestDTO(from: updatedAccount)
        let changedDTO: AccountDTO = try await client.request(method: "PUT", url: "accounts/\(id)", body: updateDTO)
        guard let changedAccount = changedDTO.toDomain() else {
            throw NSError(domain: "Invalid response", code: 0)
        }
        self.account = changedAccount
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
        let changedDTO: AccountDTO = try await client.request(method: "PUT", url: "accounts/\(id)", body: updateDTO)
        guard let changedAccount = changedDTO.toDomain() else {
            throw NSError(domain: "Invalid response", code: 0)
        }
        self.account = changedAccount
    }
}

