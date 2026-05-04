import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: String = UUID().uuidString
    var name: String = ""
    var type: IngredientType = IngredientType.other
    
    @Relationship(inverse: \RecipeIngredient.ingredient) var usages: [RecipeIngredient]?
    
    init(id: String = UUID().uuidString, name: String = "", type: IngredientType = .other) {
        self.id = id
        self.name = name
        self.type = type
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

// MARK: - Extensions for Image display

import UIKit

extension Ingredient {
    var displayImage: DisplayImageSource {
        // 1. Highest priority: System asset (with a manual check for existence)
        if UIImage(named: id) != nil {
            return .system(name)
        }
        
        // 2. Fallback: Asset name was missing or not found in xcassets
        return .placeholder
    }
}

extension IngredientDraft {
    var displayImage: DisplayImageSource {
        // 1. Highest priority: System asset (with a manual check for existence)
        if UIImage(named: id) != nil {
            return .system(name)
        }
        
        // 2. Fallback: Asset name was missing or not found in xcassets
        return .placeholder
    }
}
