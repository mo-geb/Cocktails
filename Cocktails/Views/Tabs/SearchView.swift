import SwiftUI
import SwiftData

private enum SearchTab: String, CaseIterable {
    case cocktails = "Cocktails"
    case ingredients = "Ingredients"
}

struct SearchView: View {
    @Query private var cocktails: [Cocktail]
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]

    @State private var query = ""
    @State private var selectedTab: SearchTab = .cocktails
    @State private var activeCocktailSheet: ActiveCocktailSheet?
    @State private var showSettings = false

    let cocktailColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    let ingredientColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var filteredCocktails: [Cocktail] {
        let sorted = cocktails.sorted { $0.name < $1.name }
        guard !query.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var filteredIngredients: [Ingredient] {
        guard !query.isEmpty else { return ingredients }
        return ingredients.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var groupedIngredients: [(IngredientType, [Ingredient])] {
        let groups = Dictionary(grouping: filteredIngredients) { $0.type }
        return IngredientType.allCases.compactMap { type in
            guard let items = groups[type], !items.isEmpty else { return nil }
            return (type, items)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(SearchTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)

                ScrollView {
                    if selectedTab == .cocktails {
                        cocktailGrid
                    } else {
                        ingredientGrid
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cocktails, Ingredients…")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $activeCocktailSheet) { sheet in
                switch sheet {
                case .view(let c):
                    NavigationStack {
                        CocktailDetailView(cocktail: c)
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                default: EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var cocktailGrid: some View {
        if filteredCocktails.isEmpty {
            ContentUnavailableView.search(text: query)
                .padding(.top, 60)
        } else {
            LazyVGrid(columns: cocktailColumns, spacing: 12) {
                ForEach(filteredCocktails) { cocktail in
                    CocktailGridCell(cocktail: cocktail) {
                        activeCocktailSheet = .view(cocktail)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private var ingredientGrid: some View {
        if filteredIngredients.isEmpty {
            ContentUnavailableView.search(text: query)
                .padding(.top, 60)
        } else if query.isEmpty {
            // grouped browse
            VStack(alignment: .leading, spacing: 28) {
                ForEach(groupedIngredients, id: \.0) { type, items in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(type.localizedName)
                            .font(.title3.bold())
                            .fontDesign(.rounded)
                            .padding(.horizontal)

                        LazyVGrid(columns: ingredientColumns, spacing: 10) {
                            ForEach(items) { ingredient in
                                IngredientGridCell(ingredient: ingredient)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        } else {
            // flat results when searching
            LazyVGrid(columns: ingredientColumns, spacing: 10) {
                ForEach(filteredIngredients) { ingredient in
                    IngredientGridCell(ingredient: ingredient)
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(PreviewSampleData.container)
}
