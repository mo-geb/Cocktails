import Foundation

enum IngredientRole: String, Codable, CaseIterable, Identifiable {
    case core, garnish

    var id: String { rawValue }
}
