import SwiftUI
import SwiftData

struct CocktailTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @Query(sort: \Cocktail.name) private var cocktails: [Cocktail]

    @State private var isSelecting = false
    @State private var selection = Set<UUID>()

    private var selectedCocktails: [Cocktail] {
        cocktails.filter { selection.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(isSelecting ? selectionTitle : "Cocktails")
                .toolbar { toolbarContent }
        }
    }

    private var selectionTitle: String {
        selection.isEmpty ? "Select Cocktails" : "\(selection.count) Selected"
    }

    private func startSelecting() {
        isSelecting = true
        selection = []
    }

    private func stopSelecting() {
        isSelecting = false
        selection = []
    }

    @ViewBuilder
    private var mainContent: some View {
        if cocktails.isEmpty {
            ContentUnavailableView {
                Label("No Cocktails", systemImage: "wineglass")
            } description: {
                Text("Import a library or tap + to add your first cocktail.")
            } actions: {
                Button("Import Library") { appState.openImportLibrary() }
                    .buttonStyle(.glassProminent)
            }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    ForEach(groupedCocktails) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 4) {
                                if let imageName = group.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                }
                                Text(group.name)
                            }
                            .font(.title3.bold())
                            .fontDesign(.rounded)
                            .padding(.horizontal)

                            LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
                                ForEach(group.items) { cocktail in
                                    CocktailGridCell(
                                        cocktail: cocktail,
                                        isSelected: selection.contains(cocktail.id),
                                        isSelecting: isSelecting,
                                        onDelete: isSelecting ? nil : { appState.confirmDeleteCocktail(cocktail) }
                                    ) {
                                        if isSelecting {
                                            selection.toggle(cocktail.id)
                                        } else {
                                            appState.viewCocktail(cocktail)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        @Bindable var appState = appState

        if isSelecting {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { stopSelecting() }
            }
            ToolbarItem(placement: .primaryAction) {
                if let shareItem = CocktailTransferable(cocktails: selectedCocktails) {
                    ShareLink(item: shareItem, preview: SharePreview(shareItem.fileName))
                }
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button { appState.openSettings() } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: startSelecting) {
                        Label("Select Cocktails", systemImage: "checkmark.circle")
                    }
                    Divider()
                    Menu {
                        Picker("Group By", selection: $appState.cocktailGrouping) {
                            ForEach(CocktailGrouping.allCases) { option in
                                Label(option.localizedName, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Label("Group By", systemImage: "rectangle.3.group")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .symbolVariant(appState.cocktailGrouping == .none ? .none : .fill)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: addNewCocktail) {
                    Label("Add Cocktail", systemImage: "plus")
                }
            }
        }
    }

    private func addNewCocktail() {
        guard store.canAddMore(currentCount: cocktails.count) else {
            appState.openPaywall()
            return
        }
        appState.addCocktail()
    }
    
    private struct CocktailGroup: Identifiable {
        let name: String
        let imageName: String?
        let items: [Cocktail]
        var id: String { name }
    }

    private func groupKey(for cocktail: Cocktail) -> (name: String, imageName: String?) {
        switch appState.cocktailGrouping {
        case .none:      return (String(localized: "All Cocktails"), "Glass/Empty/martini")
        case .method:    return (cocktail.method.localizedName, cocktail.method.customImageName)
        case .source:    return (cocktail.source.localizedName, cocktail.source.imageName)
        case .favourite:
            return cocktail.isFavourite
                ? (String(localized: "Favourites"), "Other/Favourite")
                : (String(localized: "All Cocktails"), "Glass/Empty/martini")
        }
    }

    private var groupedCocktails: [CocktailGroup] {
        let keyed = cocktails.map { (key: groupKey(for: $0), cocktail: $0) }
        let groups = Dictionary(grouping: keyed) { $0.key.name }
        return groups
            .sorted { l, r in
                if appState.cocktailGrouping == .favourite {
                    if l.key == String(localized: "Favourites") { return true }
                    if r.key == String(localized: "Favourites") { return false }
                }
                return l.key < r.key
            }
            .map { name, pairs in
                CocktailGroup(name: name, imageName: pairs.first?.key.imageName, items: pairs.map(\.cocktail))
            }
    }
}

#Preview(traits: .sampleData) {
    CocktailTab()
        .environment(AppState())
        .environment(StoreManager())
}

#Preview("Empty") {
    CocktailTab()
        .environment(AppState())
        .environment(StoreManager())
        .modelContainer(for: Cocktail.self, inMemory: true)
}
