import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID = UUID()
    var name: String = ""
    var type: IngredientType = IngredientType.other
    
    var imageName: String?
    
    @Relationship(inverse: \RecipeIngredient.ingredient) var usages: [RecipeIngredient]?
    
    init(name: String, type: IngredientType = .other) {
        self.id = UUID()
        self.name = name
        self.type = type
    }
}

struct IngredientDraft: Hashable {
    var name: String = ""
    var type: IngredientType = .other
    
    var imageName: String?
    
    init(name: String = "", type: IngredientType = .other) {
        self.name = name
        self.type = type
    }
    
    init(from ingredient: Ingredient) {
        self.name = ingredient.name
        self.type = ingredient.type
        self.imageName = ingredient.imageName
    }
}

// MARK: - Extensions for Image display

import UIKit

extension Ingredient {
    var displayImage: DisplayImageSource {
        // 1. Highest priority: System asset (with a manual check for existence)
        if let name = imageName, UIImage(named: name) != nil {
            return .system(name)
        }
        
        // 2. Fallback: Asset name was missing or not found in xcassets
        return .placeholder
    }
}

extension IngredientDraft {
    var displayImage: DisplayImageSource {
        // 1. Highest priority: System asset (with a manual check for existence)
        if let name = imageName, UIImage(named: name) != nil {
            return .system(name)
        }
        
        // 2. Fallback: Asset name was missing or not found in xcassets
        return .placeholder
    }
}
