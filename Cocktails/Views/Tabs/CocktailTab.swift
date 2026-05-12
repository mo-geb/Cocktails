import SwiftUI
import SwiftData

struct CocktailTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Cocktail.name) private var cocktails: [Cocktail]

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var groupedCocktails: [(String, [Cocktail])] {
        switch appState.cocktailGrouping {
        case .none:
            return [("", cocktails)]
        case .glass:
            let groups = Dictionary(grouping: cocktails) { $0.glass.localizedName }
            return groups.sorted { $0.key < $1.key }
        case .method:
            let groups = Dictionary(grouping: cocktails) { $0.method.localizedName }
            return groups.sorted { $0.key < $1.key }
        case .ice:
            let groups = Dictionary(grouping: cocktails) { $0.ice.localizedName }
            return groups.sorted { $0.key < $1.key }
        case .favourite:
            let groups = Dictionary(grouping: cocktails) { $0.isFavourite ? "Favourites" : "All Cocktails" }
            return groups.sorted { $0.key > $1.key }
        case .source:
            let groups = Dictionary(grouping: cocktails) { $0.source.localizedName }
            return groups.sorted { $0.key < $1.key }
        case .base:
            let groups = Dictionary(grouping: cocktails) { $0.baseGroup }
            return groups.sorted { l, r in
                if l.key == "No Base" { return false }
                if r.key == "No Base" { return true }
                return l.key < r.key
            }
        }
    }

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
                ForEach(groupedCocktails, id: \.0) { groupName, cocktails in
                    VStack(alignment: .leading, spacing: 12) {
                        if appState.cocktailGrouping != .none {
                            Text(groupName)
                                .font(.title3.bold())
                                .fontDesign(.rounded)
                                .padding(.horizontal)
                        }

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(cocktails) { cocktail in
                                CocktailGridCell(cocktail: cocktail, onDelete: { appState.cocktailToDelete = cocktail }) {
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
}

#Preview {
    CocktailTab()
        .environment(AppState())
        .modelContainer(PreviewSampleData.container)
}
