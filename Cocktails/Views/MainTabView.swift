import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var appState = appState
        
        TabView(selection: $appState.selectedTab) {
            Tab("Cocktails", systemImage: "wineglass", value: ActiveTab.cocktails) {
                CocktailTab()
            }

            Tab("Ingredients", systemImage: "leaf", value: ActiveTab.ingredients) {
                IngredientsTab()
            }

            Tab(value: ActiveTab.search, role: .search) {
                SearchView()
            }
        }
        .sheet(isPresented: $appState.showSettings) { SettingsView() }
        .sheet(item: $appState.activeIngredientSheet) { sheet in
            NavigationStack { sheet.contentView }
                .presentationDetents([.medium])
        }
        .sheet(item: $appState.activeCocktailSheet) { sheet in
            NavigationStack { sheet.contentView }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onOpenURL { url in
            appState.pendingImportURL = url
        }
        .sheet(isPresented: Binding(
            get: { appState.pendingImportURL != nil },
            set: { if !$0 { appState.pendingImportURL = nil } }
        )) {
            if let url = appState.pendingImportURL {
                ReceivedRecipesView(url: url, onDismiss: { appState.pendingImportURL = nil })
            }
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
            }
        } message: {
            Text("It will be removed from any recipes that use it.")
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
        .environment(AppState())
}
