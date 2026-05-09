import Foundation

enum IngredientRole: String, Codable, CaseIterable, Identifiable {
    case core
    case garnish

    var id: String { rawValue }
}
