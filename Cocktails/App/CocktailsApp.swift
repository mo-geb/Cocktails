import SwiftUI
import SwiftData

@main
struct CocktailsApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Cocktail.self,
            RecipeIngredient.self,
            Ingredient.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
        .environment(AppState())
        .modelContainer(for: Cocktail.self, inMemory: true)
}
