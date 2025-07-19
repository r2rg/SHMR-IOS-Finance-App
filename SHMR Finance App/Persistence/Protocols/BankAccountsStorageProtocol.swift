import Foundation

protocol BankAccountsStorageProtocol {
    associatedtype BankAccountType
    func fetchAccount(id: Int) async throws -> BankAccountType?
    func createAccount(_ account: BankAccountType) async throws
    func updateAccount(_ account: BankAccountType) async throws
    func deleteAccount(id: Int) async throws
    func changeBalance(id: Int, to newBalance: Decimal) async throws
    func changeCurrency(id: Int, to newCurrency: String) async throws
} 