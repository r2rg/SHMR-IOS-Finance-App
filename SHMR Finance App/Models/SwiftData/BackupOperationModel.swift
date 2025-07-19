import Foundation
import SwiftData

enum BackupActionType: String, Codable {
    case create
    case update
    case delete
}

@Model
final class BackupOperationModel {
    @Attribute(.unique) var id: Int
    var actionType: String
    var entityType: String
    var payload: Data
    var date: Date
    
    init(id: Int, actionType: BackupActionType, entityType: String, payload: Data, date: Date) {
        self.id = id
        self.actionType = actionType.rawValue
        self.entityType = entityType
        self.payload = payload
        self.date = date
    }
} 
