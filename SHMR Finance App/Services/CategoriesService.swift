final class CategoriesService {
    static let shared = CategoriesService()
    
    private init() {}
    private var categories = [
        Category(id: 1, name: "Аренда", emoji: "🏠", direction: .outcome),
        Category(id: 2, name: "Одежда", emoji: "👔", direction: .outcome),
        Category(id: 3, name: "На собачку", emoji: "🐕", direction: .outcome),
        Category(id: 4, name: "Зарплата", emoji: "🧳", direction: .income),
        Category(id: 5, name: "Подработка", emoji: "🧳", direction: .income)
    ]

    func allCategories() async throws -> [Category] {
        return categories
    }
    
    func categories(for direction: Direction) async throws -> [Category] {
        let all = try await allCategories()
        return all.filter { $0.direction == direction }
    }
}
