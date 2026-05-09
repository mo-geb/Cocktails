import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: String = UUID().uuidString
    var name: String = ""
    var type: IngredientType = IngredientType.other
    var isStocked: Bool = false

    @Relationship(inverse: \RecipeIngredient.ingredient) var usages: [RecipeIngredient]?

    init(id: String = UUID().uuidString, name: String = "", type: IngredientType = .other, isStocked: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.isStocked = isStocked
    }
}

struct IngredientDraft: Hashable {
    var id: String
    var name: String = ""
    var type: IngredientType = .other

    init(id: String = UUID().uuidString, name: String = "", type: IngredientType = .other) {
        self.id = id
        self.name = name
        self.type = type
    }

    init(from ingredient: Ingredient) {
        self.id = ingredient.id
        self.name = ingredient.name
        self.type = ingredient.type
    }
}

import UIKit

protocol IngredientImageProviding {
    var id: String { get }
}

extension IngredientImageProviding {
    var displayImage: DisplayImageSource {
        if UIImage(named: "Ingredient/" + id) != nil {
            return .system("Ingredient/" + id)
        }
        return .placeholder
    }
}

extension Ingredient: IngredientImageProviding {}
extension IngredientDraft: IngredientImageProviding {}
