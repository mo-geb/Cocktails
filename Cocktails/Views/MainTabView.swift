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

            Tab("Inventory", systemImage: "cabinet", value: ActiveTab.inventory) {
                InventoryTab()
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
                ImportPreviewView(url: url, onDismiss: { appState.pendingImportURL = nil })
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
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
        .environment(AppState())
}
