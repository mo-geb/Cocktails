import SwiftUI
import SwiftData

struct SampleDataModifier: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        await MainActor.run { PreviewSampleData.container }
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var sampleData: Self = .modifier(SampleDataModifier())
}

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

    static var mockIngredient: Ingredient {
        let fetchDescriptor = FetchDescriptor<Ingredient>()
        return try! container.mainContext.fetch(fetchDescriptor).first!
    }
}
