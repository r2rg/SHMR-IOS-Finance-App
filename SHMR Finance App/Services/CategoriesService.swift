final class CategoriesService {
    private var categories = [
        Category(id: 1, name: "Зарплата", emoji: "💰", direction: .income),
        Category(id: 2, name: "Продукты", emoji: "🛒", direction: .outcome),
        Category(id: 3, name: "Транспорт", emoji: "🚌", direction: .outcome)
    ]

    func allCategories() async throws -> [Category] {
        return categories
    }
    
    func categories(for direction: Direction) async throws -> [Category] {
        let all = try await allCategories()
        return all.filter { $0.direction == direction }
    }
}
