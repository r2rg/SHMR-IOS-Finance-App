import Foundation
import SwiftData

@MainActor
final class SwiftDataCategoriesStorage: CategoriesStorageProtocol {
    typealias CategoryType = Category
    private let context: ModelContext
    
    init(container: ModelContainer) {
        self.context = container.mainContext
    }
    
    func fetchAllCategories() async throws -> [Category] {
        let fetchDescriptor = FetchDescriptor<CategoryModel>()
        let models = try context.fetch(fetchDescriptor)
        return models.map { model in
            Category(
                id: model.id,
                name: model.name,
                emoji: Character(model.emoji),
                direction: Direction(rawValue: model.direction) ?? .outcome
            )
        }
    }
    
    func fetchCategories(for direction: Direction) async throws -> [Category] {
        let fetchDescriptor = FetchDescriptor<CategoryModel>(predicate: #Predicate { $0.direction == direction.rawValue })
        let models = try context.fetch(fetchDescriptor)
        return models.map { model in
            Category(
                id: model.id,
                name: model.name,
                emoji: Character(model.emoji),
                direction: direction
            )
        }
    }
    
    func updateCategories(_ categories: [Category]) async throws {
        let fetchDescriptor = FetchDescriptor<CategoryModel>()
        let oldModels = try context.fetch(fetchDescriptor)
        for model in oldModels {
            context.delete(model)
        }
        for category in categories {
            let model = CategoryModel(
                id: category.id,
                name: category.name,
                emoji: String(category.emoji),
                direction: category.direction.rawValue
            )
            context.insert(model)
        }
        try context.save()
    }
} 
