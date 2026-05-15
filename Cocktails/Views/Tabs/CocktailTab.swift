import SwiftUI
import SwiftData

struct CocktailTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Cocktail.name) private var cocktails: [Cocktail]

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            mainContent
                .navigationTitle("Cocktails")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { appState.showSettings = true } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Group By", selection: $appState.cocktailGrouping) {
                                ForEach(CocktailGrouping.allCases) { option in
                                    Label(option.localizedName, systemImage: option.systemImage)
                                        .tag(option)
                                }
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
    }

    @ViewBuilder
    private var mainContent: some View {
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

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(group.items) { cocktail in
                                CocktailGridCell(cocktail: cocktail, onEdit: { appState.activeCocktailSheet = .edit(cocktail) }, onDelete: { appState.cocktailToDelete = cocktail }) {
                                    appState.activeCocktailSheet = .view(cocktail)
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

    private func addNewCocktail() {
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
        case .ice:       return (cocktail.ice.localizedName, cocktail.ice.imageName)
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
        let groups = Dictionary(grouping: cocktails) { groupKey(for: $0).name }
        return groups
            .sorted { l, r in
                if l.key == "No Base" { return false }
                if r.key == "No Base" { return true }
                return l.key < r.key
            }
            .map { key, items in
                CocktailGroup(name: key, imageName: groupKey(for: items[0]).imageName, items: items)
            }
    }
}

#Preview(traits: .sampleData) {
    CocktailTab()
        .environment(AppState())
}
