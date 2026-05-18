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
            ContentUnavailableView(
                "No Cocktails",
                systemImage: "wineglass",
                description: Text("Tap + to add your first cocktail.")
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(groupedCocktails) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            if appState.cocktailGrouping != .none {
                                HStack(spacing: 4) {
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
                            }

                            LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
                                ForEach(group.items) { cocktail in
                                    CocktailGridCell(
                                        cocktail: cocktail,
                                        isSelected: selection.contains(cocktail.id),
                                        isSelecting: isSelecting,
                                        onEdit: isSelecting ? nil : { appState.activeCocktailSheet = .edit(cocktail) },
                                        onDelete: isSelecting ? nil : { appState.cocktailToDelete = cocktail }
                                    ) {
                                        if isSelecting {
                                            selection.toggle(cocktail.id)
                                        } else {
                                            appState.activeCocktailSheet = .view(cocktail)
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
                Button { appState.showSettings = true } label: {
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
            appState.showPaywall = true
            return
        }
        appState.activeCocktailSheet = .new(CocktailDraft())
    }
    
    private struct CocktailGroup: Identifiable {
        let name: String
        let imageName: String?
        let items: [Cocktail]
        var id: String { name }
    }

    private func groupKey(for cocktail: Cocktail) -> (name: String, imageName: String?) {
        switch appState.cocktailGrouping {
        case .none:      return ("", nil)
        case .glass:     return (cocktail.glass.localizedName, cocktail.glass.imageNameEmpty)
        case .method:    return (cocktail.method.localizedName, cocktail.method.customImageName)
        case .source:    return (cocktail.source.localizedName, cocktail.source.imageName)
        case .favourite:
            return cocktail.isFavourite
                ? (String(localized: "Favourites"), nil)
                : (String(localized: "All Cocktails"), nil)
        case .base:
            let name = cocktail.baseGroup
            let image = Cocktail.baseTypePriority.first { $0.localizedName == name }?.imageName
            return (name, image)
        }
    }

    private var groupedCocktails: [CocktailGroup] {
        let keyed = cocktails.map { (key: groupKey(for: $0), cocktail: $0) }
        let groups = Dictionary(grouping: keyed) { $0.key.name }
        return groups
            .sorted { l, r in
                if l.key == "No Base" { return false }
                if r.key == "No Base" { return true }
                return l.key < r.key
            }
            .map { name, pairs in
                CocktailGroup(name: name, imageName: pairs[0].key.imageName, items: pairs.map(\.cocktail))
            }
    }
}

#Preview(traits: .sampleData) {
    CocktailTab()
        .environment(AppState())
        .environment(StoreManager())
}
