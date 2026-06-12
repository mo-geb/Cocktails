import SwiftUI
import SwiftData
import StoreKit

@main
struct CocktailsApp: App {
    @State private var appState = AppState()
    @State private var store = StoreManager()

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
                .environment(store)
                .currentEntitlementTask(for: StoreManager.unlimitedProductID) { state in
                    if case .success(let entitlement) = state {
                        await store.updateEntitlement(from: entitlement)
                    }
                }
                .onInAppPurchaseCompletion { _, result in
                    await store.handlePurchaseResult(result)
                }
                .task {
                    await store.processUnfinishedTransactions()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
        .environment(AppState())
        .environment(StoreManager())
        .modelContainer(for: Cocktail.self, inMemory: true)
}
