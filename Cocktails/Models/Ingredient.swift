import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: String = UUID().uuidString
    var name: String = ""
    var type: IngredientType = IngredientType.other
    var isStocked: Bool = false
    var imageName: String? = nil

    @Relationship(inverse: \RecipeIngredient.ingredient) var usages: [RecipeIngredient]?

    var localizedName: String {
        let key = "ingredient.\(id)"
        let localized = String(localized: String.LocalizationValue(key))
        return localized == key ? name : localized
    }

    init(id: String = UUID().uuidString, name: String = "", type: IngredientType = .other, isStocked: Bool = false, imageName: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.isStocked = isStocked
        self.imageName = imageName
    }
}

struct IngredientDraft: Hashable {
    var id: String
    var name: String = ""
    var type: IngredientType = .other
    var imageName: String? = nil

    var localizedName: String {
        let key = "ingredient.\(id)"
        let localized = String(localized: String.LocalizationValue(key))
        return localized == key ? name : localized
    }

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

import UIKit

protocol IngredientImageProviding {
    var id: String { get }
    var imageName: String? { get }
}

extension IngredientImageProviding {
    var displayImage: DisplayImageSource {
        let assetName = "Ingredient/" + (imageName ?? id)
        if UIImage(named: assetName) != nil {
            return .system(assetName)
        }
        return .placeholder
    }
}


extension Ingredient: IngredientImageProviding {}
extension IngredientDraft: IngredientImageProviding {}
