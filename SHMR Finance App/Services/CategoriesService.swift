final class CategoriesService {
    static let shared = CategoriesService()
    let client = NetworkClient()
    private init() {}

    func allCategories() async throws -> [Category] {
        let dtos: [CategoryDTO] = try await client.request(method: "GET", url: "categories")
        return dtos.compactMap { $0.toDomain() }
    }
    
    func categories(for direction: Direction) async throws -> [Category] {
        let isIncome = (direction == .income) ? "true" : "false"
        let dtos: [CategoryDTO] = try await client.request(method: "GET", url: "categories/type/\(isIncome)")
        return dtos.compactMap { $0.toDomain() }
    }
}
