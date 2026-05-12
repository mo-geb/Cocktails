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
        .sheet(item: $appState.activeCocktailSheet) { sheet in
            NavigationStack { sheet.contentView }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

#Preview {
    MainTabView()
        .environment(AppState())
        .modelContainer(PreviewSampleData.container)
}
