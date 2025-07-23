// Сервис подлежит пределыванию
@MainActor
final class CategoriesService {
    static let shared = CategoriesService()
    let client = NetworkClient()
    private let localStorage: SwiftDataCategoriesStorage
    private init() {
        let container = SHMR_Finance_AppApp.sharedModelContainer
        self.localStorage = SwiftDataCategoriesStorage(container: container)
    }

    func allCategories() async throws -> [Category] {
        do {
            let dtos: [CategoryDTO] = try await client.request(method: "GET", url: "categories")
            let categories = dtos.compactMap { $0.toDomain() }
            try await localStorage.updateCategories(categories)
            return categories
        } catch {
            return try await localStorage.fetchAllCategories()
        }
    }
    
    func categories(for direction: Direction) async throws -> [Category] {
        do {
            let isIncome = (direction == .income) ? "true" : "false"
            let dtos: [CategoryDTO] = try await client.request(method: "GET", url: "categories/type/\(isIncome)")
            let categories = dtos.compactMap { $0.toDomain() }
            try await localStorage.updateCategories(categories)
            return categories
        } catch {
            return try await localStorage.fetchCategories(for: direction)
        }
    }
}
