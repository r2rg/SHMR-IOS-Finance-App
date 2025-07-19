import Foundation
import SwiftData

@MainActor
final class SwiftDataBackupStorage: BackupStorageProtocol {
    typealias OperationType = BackupOperationModel
    private let context: ModelContext
    
    init(container: ModelContainer) {
        self.context = container.mainContext
    }
    
    func fetchAllBackupOperations() async throws -> [BackupOperationModel] {
        let fetchDescriptor = FetchDescriptor<BackupOperationModel>()
        return try context.fetch(fetchDescriptor)
    }
    
    func addOrUpdateBackupOperation(_ operation: BackupOperationModel) async throws {
        let id = operation.id
        let entityType = operation.entityType
        let fetchDescriptor = FetchDescriptor<BackupOperationModel>(predicate: #Predicate { model in
            model.id == id
        })
        let models = try context.fetch(fetchDescriptor)
        if let existing = models.first(where: { $0.entityType == entityType }) {
            existing.actionType = operation.actionType
            existing.payload = operation.payload
            existing.date = operation.date
        } else {
            context.insert(operation)
        }
        try context.save()
    }
    
    func removeBackupOperation(id: Int, entityType: String) async throws {
        let fetchDescriptor = FetchDescriptor<BackupOperationModel>(predicate: #Predicate { model in
            model.id == id
        })
        let models = try context.fetch(fetchDescriptor)
        for model in models where model.entityType == entityType {
            context.delete(model)
        }
        try context.save()
    }
    
    func removeBackupOperations(ids: [Int], entityType: String) async throws {
        let fetchDescriptor = FetchDescriptor<BackupOperationModel>()
        let models = try context.fetch(fetchDescriptor)
        for model in models where ids.contains(model.id) && model.entityType == entityType {
            context.delete(model)
        }
        try context.save()
    }
} 