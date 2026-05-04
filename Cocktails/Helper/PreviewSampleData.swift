import SwiftUI
import SwiftData

@MainActor
struct PreviewSampleData {
    static let container: ModelContainer = {
        let schema = Schema([Cocktail.self, RecipeIngredient.self, Ingredient.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        // 1. Create Base Ingredients
        let rum = Ingredient(name: "White Rum", type: .spirit)
        let mint = Ingredient(name: "Mint Leaves", type: .garnish)
        let syrup = Ingredient(name: "Simple Syrup", type: .syrup)
        let lime = Ingredient(name: "Fresh Lime Juice", type: .juice)
        let curacao = Ingredient(name: "Dry Curaçao", type: .liqueur)
        let limeWheel = Ingredient(name: "Lime Wheel", type: .garnish)
        
        let baseIngredients = [rum, mint, syrup, lime, curacao, limeWheel]
        
        container.mainContext.insert(rum)
        container.mainContext.insert(mint)
        container.mainContext.insert(syrup)
        container.mainContext.insert(lime)
        container.mainContext.insert(curacao)
        container.mainContext.insert(limeWheel)
        
        // 2. Create Cocktail Associations
        let mojitoIngredients = [
            RecipeIngredient(amount: 60.0, unit: .ml, note: "Appleton Estate preferred", ingredient: rum),
            RecipeIngredient(amount: 30.0, unit: .ml, note: "", ingredient: lime),
            RecipeIngredient(amount: 22.0, unit: .ml, note: "", ingredient: syrup),
            RecipeIngredient(amount: 10.0, unit: .piece, note: "Slap it first!", ingredient: mint),
            RecipeIngredient(amount: 1.0, unit: .piece, note: "", ingredient: limeWheel)
        ]
        
        let mojito = Cocktail(
            name: "Mojito",
            notes: "Muddle mint and syrup. Add rum, lime juice and ice. Top with club soda. Garnish with a mint sprig.",
            glass: .highball,
            method: .build,
            ice: .cubed,
            ingredients: mojitoIngredients
        )
        container.mainContext.insert(mojito)
        
        return container
    }()
    
    // Convenience Accessor for Parameter passing
    static var mockCocktail: Cocktail {
        let fetchDescriptor = FetchDescriptor<Cocktail>()
        return try! container.mainContext.fetch(fetchDescriptor).first!
    }
}
