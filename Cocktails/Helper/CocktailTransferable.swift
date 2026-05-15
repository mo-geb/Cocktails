import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

extension UTType {
    static let cocktailRecipe = UTType(exportedAs: "com.mo.Cocktails.recipe")
}

struct CocktailTransferable: Transferable {
    let cocktailName: String
    let data: Data

    @MainActor
    init?(cocktail: Cocktail) {
        guard let data = try? JSONEncoder().encode(SharedCocktailPackage(from: cocktail)) else { return nil }
        self.cocktailName = cocktail.name
        self.data = data
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .cocktailRecipe) { item in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(item.cocktailName)
                .appendingPathExtension("cocktail")
            try item.data.write(to: url)
            return SentTransferredFile(url)
        }
    }
}

extension SharedCocktailPackage {
    init(from cocktail: Cocktail) {
        let allRecipeIngredients = cocktail.ingredients ?? []

        let uniqueIngredients = allRecipeIngredients
            .compactMap(\.ingredient)
            .reduce(into: [String: Ingredient]()) { $0[$1.id] = $1 }
            .values
            .map { IngredientDTO(id: $0.id, name: $0.name, type: $0.type) }

        let core = allRecipeIngredients
            .filter { $0.role == .core }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { RecipeIngredientDTO(from: $0) }

        let garnishes = allRecipeIngredients
            .filter { $0.role == .garnish }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { RecipeIngredientDTO(from: $0) }

        self.cocktail = CocktailDTO(
            name: cocktail.name,
            imageName: cocktail.imageName,
            glass: cocktail.glass,
            method: cocktail.method,
            ice: cocktail.ice,
            ingredients: core,
            garnishes: garnishes.isEmpty ? nil : garnishes,
            notes: cocktail.notes.isEmpty ? nil : cocktail.notes
        )
        self.ingredients = Array(uniqueIngredients)
    }
}

extension RecipeIngredientDTO {
    init(from ri: RecipeIngredient) {
        self.init(
            ingredientId: ri.ingredient?.id ?? "",
            amount: ri.amount,
            unit: ri.unit == .none ? nil : ri.unit,
            note: ri.note.isEmpty ? nil : ri.note
        )
    }
}
