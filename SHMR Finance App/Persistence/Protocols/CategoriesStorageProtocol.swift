import Foundation

protocol CategoriesStorageProtocol {
    associatedtype CategoryType
    func fetchAllCategories() async throws -> [CategoryType]
    func fetchCategories(for direction: Direction) async throws -> [CategoryType]
    func updateCategories(_ categories: [CategoryType]) async throws
} 