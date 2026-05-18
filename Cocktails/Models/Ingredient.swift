import Foundation
import SwiftData

protocol IngredientNaming {
    var id: String { get }
    var name: String { get }
}

extension IngredientNaming {
    var localizedName: String {
        let key = "ingredient.\(id)"
        let localized = String(localized: String.LocalizationValue(key))
        return localized == key ? name : localized
    }
}

@Model
final class Ingredient: IngredientNaming {
    var id: String = UUID().uuidString
    var name: String = ""
    var type: IngredientType = IngredientType.other
    var isStocked: Bool = false
    var imageName: String? = nil

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.ingredient) var usages: [RecipeIngredient]?

    init(id: String = UUID().uuidString, name: String = "", type: IngredientType = .other, isStocked: Bool = false, imageName: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.isStocked = isStocked
        self.imageName = imageName
    }
}

struct IngredientDraft: Hashable, IngredientNaming {
    var id: String
    var name: String = ""
    var type: IngredientType = .other
    var imageName: String? = nil

    init(id: String = UUID().uuidString, name: String = "", type: IngredientType = .other, imageName: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.imageName = imageName
    }

    init(from ingredient: Ingredient) {
        self.id = ingredient.id
        self.name = ingredient.name
        self.type = ingredient.type
        self.imageName = ingredient.imageName
    }
}

