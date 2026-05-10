import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: ActiveTab = .cocktails
    @State private var preferredSearchTab: SearchTab = .cocktails

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Cocktails", systemImage: "wineglass", value: .cocktails) {
                CocktailTab()
            }

            Tab("Inventory", systemImage: "cabinet", value: .inventory) {
                InventoryTab()
            }

            Tab("Dev", systemImage: "hammer", value: .debug) {
                DebugTab()
            }

            Tab(value: .search, role: .search) {
                SearchView(preferredTab: preferredSearchTab)
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            switch newTab {
            case .cocktails, .debug: preferredSearchTab = .cocktails
            case .inventory:         preferredSearchTab = .ingredients
            default: break
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewSampleData.container)
}
