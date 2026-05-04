import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: ActiveTab = .cocktails

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
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewSampleData.container)
}
