import Foundation

@MainActor
protocol BackupStorageProtocol {
    associatedtype OperationType
    func fetchAllBackupOperations() async throws -> [OperationType]
    func addOrUpdateBackupOperation(_ operation: OperationType) async throws
    func removeBackupOperation(id: Int, entityType: String) async throws
    func removeBackupOperations(ids: [Int], entityType: String) async throws
} 