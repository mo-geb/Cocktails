import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var deleteHapticTrigger = false

    var body: some View {
        @Bindable var appState = appState
        
        TabView(selection: $appState.selectedTab) {
            Tab("Cocktails", systemImage: "wineglass", value: ActiveTab.cocktails) {
                CocktailTab()
            }

            Tab("Ingredients", systemImage: "leaf", value: ActiveTab.ingredients) {
                IngredientTab()
            }

            Tab(value: ActiveTab.search, role: .search) {
                SearchView()
            }
        }
        .tabViewSearchActivation(.searchTabSelection)
        .sensoryFeedback(.warning, trigger: deleteHapticTrigger)
        .fullScreenCover(isPresented: $appState.showOnboarding) {
            OnboardingView()
        }
        .fullScreenCover(isPresented: $appState.showPaywall) {
            PaywallView()
        }
        .sheet(item: $appState.activeSheet) { sheet in
            appSheetContent(sheet)
        }
        .onOpenURL { url in
            appState.openReceivedRecipes(url)
        }
        .cocktailDeletionDialog($appState.cocktailToDelete)
        .confirmationDialog(
            "Delete \"\(appState.ingredientToDelete?.name ?? "")\"?",
            isPresented: .init(presence: $appState.ingredientToDelete),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let i = appState.ingredientToDelete { modelContext.delete(i) }
                appState.ingredientToDelete = nil
                deleteHapticTrigger.toggle()
            }
        } message: {
            Text("It will be removed from any recipes that use it.")
        }
    }

    @ViewBuilder
    private func appSheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .settings:
            SettingsView()
        case .importLibrary:
            NavigationStack {
                RecipeLibrariesView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(role: .close) { appState.activeSheet = nil }
                        }
                    }
            }
        case .receivedRecipes(let url):
            ReceivedRecipesView(url: url, onDismiss: { appState.activeSheet = nil })
        case .ingredientSheet(let ingredientSheet):
            NavigationStack { ingredientSheet.contentView }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        case .cocktailsWithIngredient(let ingredient):
            CocktailsWithIngredientView(ingredient: ingredient)
        case .newCocktail(let draft):
            NewCocktailSheetView(draft: draft)
                .presentationDetents([.large])
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
        .environment(AppState())
        .environment(StoreManager())
        .modelContainer(for: Cocktail.self, inMemory: true)
}
