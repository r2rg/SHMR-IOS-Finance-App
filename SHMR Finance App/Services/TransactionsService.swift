import Foundation

final class TransactionsService {
    static let shared = TransactionsService()
    let client = NetworkClient()
    private init() {}

    func getTransactions(accountId: Int, from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        let url = "transactions/account/\(accountId)/period?startDate=\(start)&endDate=\(end)"
        let dtos: [TransactionResponseDTO] = try await client.request(method: "GET", url: url)
        return dtos.compactMap { $0.toDomain() }
    }

    func createTransaction(dto transactionDTO: TransactionRequestDTO) async throws {
        _ = try await client.request(method: "POST", url: "transactions", body: transactionDTO)
    }

    func editTransaction(_ transaction: Transaction) async throws {
        let dto = TransactionRequestDTO(from: transaction)
        _ = try await client.request(method: "PUT", url: "transactions/\(transaction.id)", body: dto)
    }

    func deleteTransaction(byId id: Int) async throws {
        _ = try await client.request(method: "DELETE", url: "transactions/\(id)")
    }
}
