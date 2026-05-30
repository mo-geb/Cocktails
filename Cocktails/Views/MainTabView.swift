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
        .sensoryFeedback(.warning, trigger: deleteHapticTrigger)
        .fullScreenCover(isPresented: $appState.showOnboarding) {
            OnboardingView()
        }
        .fullScreenCover(isPresented: $appState.showPaywall) {
            PaywallView()
        }
        .sheet(item: $appState.activeSheet) { sheet in
            appSheetContent(sheet)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $appState.activeIngredientSheet) { sheet in
            NavigationStack { sheet.contentView }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .cocktailSheet($appState.activeCocktailSheet)
        .onOpenURL { url in
            appState.openReceivedRecipes(url)
        }
        .confirmationDialog(
            "Delete \"\(appState.cocktailToDelete?.name ?? "")\"?",
            isPresented: Binding(
                get: { appState.cocktailToDelete != nil },
                set: { if !$0 { appState.cocktailToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let c = appState.cocktailToDelete { modelContext.delete(c) }
                appState.cocktailToDelete = nil
                deleteHapticTrigger.toggle()
            }
        }
        .confirmationDialog(
            "Delete \"\(appState.ingredientToDelete?.name ?? "")\"?",
            isPresented: Binding(
                get: { appState.ingredientToDelete != nil },
                set: { if !$0 { appState.ingredientToDelete = nil } }
            ),
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
            NavigationStack { RecipeLibrariesView() }
        case .receivedRecipes(let url):
            ReceivedRecipesView(url: url, onDismiss: { appState.activeSheet = nil })
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
        .environment(AppState())
        .environment(StoreManager())
        .modelContainer(for: Cocktail.self, inMemory: true)
}
