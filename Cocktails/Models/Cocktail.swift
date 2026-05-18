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
    var isFavourite: Bool = false

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
    var source: RecipeSource = .custom
    var isFavourite: Bool = false

    var notes: String = ""

    var imageData: Data? = nil
    var imageName: String? = nil

    var ingredients: [RecipeIngredientDraft] = []

    init(from cocktail: Cocktail? = nil) {
        guard let cocktail else { return }
        name = cocktail.name
        notes = cocktail.notes
        glass = cocktail.glass
        method = cocktail.method
        ice = cocktail.ice
        source = cocktail.source
        isFavourite = cocktail.isFavourite
        imageData = cocktail.imageData
        imageName = cocktail.imageName
        ingredients = cocktail.ingredients?.map { RecipeIngredientDraft(from: $0) } ?? []
    }
}

extension Cocktail {
    var coreIngredients: [RecipeIngredient] {
        (ingredients ?? []).filter { $0.role == .core }
    }

    var garnishIngredients: [RecipeIngredient] {
        (ingredients ?? []).filter { $0.role == .garnish }
    }
}

extension Cocktail {
    static let baseTypePriority: [IngredientType] = [.spirit, .liqueur, .fortifiedWine]

    var baseGroup: String {
        let coreTypes = (ingredients ?? [])
            .filter { $0.role == .core }
            .compactMap { $0.ingredient?.type }
        for type in Self.baseTypePriority {
            if coreTypes.contains(type) { return type.localizedName }
        }
        return "No Base"
    }
}
