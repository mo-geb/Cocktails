import Foundation

enum IngredientRole: String, Codable, CaseIterable, Identifiable {
    case core
    case garnish
    // We can add `optional` or others in the future if needed

    var id: String { rawValue }
}
