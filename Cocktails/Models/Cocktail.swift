import Foundation
import SwiftData

@Model
final class Cocktail {
    var id: UUID = UUID()
    var name: String = ""
    
    var glass: GlassType = GlassType.rocks
    var method: PreparationMethod = PreparationMethod.build
    var ice: IceType = IceType.cubed
    var source: RecipeSource = RecipeSource.custom
    
    var notes: String = ""

    @Attribute(.externalStorage) var imageData: Data?
    var imageName: String?
    
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.cocktail) var ingredients: [RecipeIngredient]?
    
    init(name: String = "",
         notes: String = "",
         glass: GlassType = .rocks,
         method: PreparationMethod = .build,
         ice: IceType = .cubed,
         source: RecipeSource = .custom,
         imageData: Data? = nil,
         imageName: String? = nil,
         ingredients: [RecipeIngredient] = []) {
        self.name = name

        self.notes = notes
        self.glass = glass
        self.method = method
        self.ice = ice
        self.source = source
        self.imageData = imageData
        self.imageName = imageName
        self.ingredients = ingredients
    }
}

struct CocktailDraft: Hashable {
    var name: String = ""
    
    var glass: GlassType = .highball
    var method: PreparationMethod = .build
    var ice: IceType = .cubed
    var source: RecipeSource = RecipeSource.custom

    var notes: String = ""

    var imageData: Data? = nil
    var imageName: String? = nil

    var ingredients: [RecipeIngredientDraft] = []
    
    init(from cocktail: Cocktail? = nil) {
        guard let cocktail = cocktail else { return }
        self.name = cocktail.name
        self.notes = cocktail.notes
        self.glass = cocktail.glass
        self.method = cocktail.method
        self.ice = cocktail.ice
        self.source = cocktail.source
        self.imageData = cocktail.imageData
        self.imageName = cocktail.imageName
        
        if let existing = cocktail.ingredients {
            self.ingredients = existing.map { RecipeIngredientDraft(from: $0) }
        }
    }
}

import UIKit

extension Cocktail {
    var displayImage: DisplayImageSource {
        // 1. Highest priority: User's custom uploaded photo
        if let data = imageData, let uiImage = UIImage(data: data) {
            return .custom(uiImage)
        }
        
        // 2. Secondary: System asset (with a manual check for existence)
        if let name = imageName, UIImage(named: name) != nil {
            return .system(name)
        }
        
        // 3. Fallback: Asset name was missing or not found in xcassets
        return .placeholder
    }
}

extension CocktailDraft {
    var displayImage: DisplayImageSource {
        // 1. Highest priority: User's custom uploaded photo
        if let data = imageData, let uiImage = UIImage(data: data) {
            return .custom(uiImage)
        }
        
        // 2. Secondary: System asset (with a manual check for existence)
        if let name = imageName, UIImage(named: name) != nil {
            return .system(name)
        }
        
        // 3. Fallback: Asset name was missing or not found in xcassets
        return .placeholder
    }
}
