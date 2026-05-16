// MARK: - DTOs

import Foundation

struct IngredientDTO: Codable {
    let id: String
    let name: String
    let type: IngredientType
}

struct RecipeIngredientDTO: Codable {
    let ingredientId: String
    let amount: Double
    let unit: MeasurementUnit?
    let note: String?
}

struct CocktailDTO: Codable {
    let name: String
    let imageName: String?
    let glass: GlassType
    let method: PreparationMethod
    let ice: IceType
    let ingredients: [RecipeIngredientDTO]
    let garnishes: [RecipeIngredientDTO]?
    let notes: String?
}

struct SharedCocktailPackage: Codable {
    let cocktails: [CocktailDTO]
    let ingredients: [IngredientDTO]
}

extension CocktailDTO: CocktailImageProviding {
    var imageData: Data? { nil }
}

// MARK: - Import Result

struct ImportResult {
    let ingredientsInserted: Int
    let ingredientsSkipped: Int
    let cocktailsInserted: Int
    let unmappedIngredientRefs: [(cocktail: String, ingredientName: String)]

    var summary: String {
        var lines = [
            "Cocktails inserted: \(cocktailsInserted)",
            "Ingredients inserted: \(ingredientsInserted)",
            "Ingredients already present (skipped): \(ingredientsSkipped)"
        ]
        if !unmappedIngredientRefs.isEmpty {
            lines.append("⚠️ Unresolved ingredient refs: \(unmappedIngredientRefs.count)")
            for ref in unmappedIngredientRefs {
                lines.append("  • \(ref.cocktail) → \"\(ref.ingredientName)\"")
            }
        }
        return lines.joined(separator: "\n")
    }
}
