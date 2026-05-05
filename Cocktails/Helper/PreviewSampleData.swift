import SwiftUI
import SwiftData

@MainActor
struct PreviewSampleData {
    static let container: ModelContainer = {
        let schema = Schema([Cocktail.self, RecipeIngredient.self, Ingredient.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        let importer = CocktailImporter(context: container.mainContext)
        try! importer.importSelectedCocktails(names: ["Espresso Martini", "B52", "Piña Colada"], from: .ebsInter2023)

        return container
    }()

    static var mockCocktail: Cocktail {
        let fetchDescriptor = FetchDescriptor<Cocktail>()
        return try! container.mainContext.fetch(fetchDescriptor).first!
    }
    
    static var mockCocktails: [Cocktail] {
        let fetchDescriptor = FetchDescriptor<Cocktail>()
        return try! container.mainContext.fetch(fetchDescriptor)
    }
}
