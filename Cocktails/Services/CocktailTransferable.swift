import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

extension UTType {
    static let cocktailRecipe = UTType(exportedAs: "com.mo.Cocktails.recipe")
}

struct CocktailTransferable: Transferable {
    let fileName: String
    let data: Data

    @MainActor
    init?(cocktails: [Cocktail]) {
        guard !cocktails.isEmpty,
              let data = try? JSONEncoder().encode(SharedCocktailPackage(from: cocktails)) else { return nil }
        self.fileName = cocktails.count == 1 ? cocktails[0].name : "\(cocktails.count) Cocktails"
        self.data = data
    }

    @MainActor
    init?(cocktail: Cocktail) {
        self.init(cocktails: [cocktail])
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .cocktailRecipe) { item in
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent(item.fileName).appendingPathExtension("cocktail")
            try item.data.write(to: url)
            return SentTransferredFile(url)
        }
    }
}

extension SharedCocktailPackage {
    init(from cocktails: [Cocktail]) {
        let uniqueIngredients = cocktails
            .flatMap { $0.ingredients ?? [] }
            .compactMap(\.ingredient)
            .reduce(into: [String: Ingredient]()) { $0[$1.id] = $1 }
            .values
            .map { IngredientDTO(id: $0.id, name: $0.name, type: $0.type) }

        self.cocktails = cocktails.map { CocktailDTO(from: $0) }
        self.ingredients = Array(uniqueIngredients)
    }
}

extension CocktailDTO {
    init(from cocktail: Cocktail) {
        let core = cocktail.coreIngredients.sorted { $0.sortOrder < $1.sortOrder }.map { RecipeIngredientDTO(from: $0) }
        let garnishes = cocktail.garnishIngredients.sorted { $0.sortOrder < $1.sortOrder }.map { RecipeIngredientDTO(from: $0) }
        self.init(
            name: cocktail.name,
            imageName: cocktail.imageName,
            glass: cocktail.glass,
            method: cocktail.method,
            ice: cocktail.ice,
            ingredients: core,
            garnishes: garnishes.isEmpty ? nil : garnishes,
            notes: cocktail.notes.isEmpty ? nil : cocktail.notes
        )
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
