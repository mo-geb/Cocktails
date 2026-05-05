import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    var id: UUID = UUID()
    var amount: Double = 0.0
    var unit: MeasurementUnit = MeasurementUnit.ml
    var note: String = ""

    var cocktail: Cocktail?
    var ingredient: Ingredient?

    init(amount: Double = 0.0, unit: MeasurementUnit = .ml, note: String = "", ingredient: Ingredient? = nil) {
        self.id = UUID()
        self.amount = amount
        self.unit = unit
        self.note = note
        self.ingredient = ingredient
    }
}

struct RecipeIngredientDraft: Hashable, Identifiable {
    var id: UUID = UUID()
    var amount: Double?
    var unit: MeasurementUnit = .ml
    var note: String = ""

    var ingredient: IngredientDraft

    init(amount: Double? = nil, unit: MeasurementUnit = .ml, note: String = "", ingredient: IngredientDraft = IngredientDraft()) {
        self.amount = amount
        self.unit = unit
        self.note = note
        self.ingredient = ingredient
    }

    init(from recipeIngredient: RecipeIngredient) {
        self.id = recipeIngredient.id
        self.amount = recipeIngredient.amount
        self.unit = recipeIngredient.unit
        self.note = recipeIngredient.note
        self.ingredient = recipeIngredient.ingredient.map { IngredientDraft(from: $0) } ?? IngredientDraft()
    }
}
