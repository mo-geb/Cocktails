import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @Query(sort: \Cocktail.name) private var cocktails: [Cocktail]
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]

    @State private var query = ""
    @State private var selectedTab: SearchTab = .cocktails


    private var filteredCocktails: [Cocktail] {
        guard !query.isEmpty else { return cocktails }
        return cocktails.filter { $0.name.localizedStandardContains(query) }
    }

    private var filteredIngredients: [Ingredient] {
        guard !query.isEmpty else { return ingredients }
        return ingredients.filter { $0.name.localizedStandardContains(query) }
    }

    private var showCocktailSuggestion: Bool {
        guard !query.isEmpty else { return false }
        return !cocktails.contains { $0.name.localizedCaseInsensitiveCompare(query) == .orderedSame }
    }

    private var showIngredientSuggestion: Bool {
        guard !query.isEmpty else { return false }
        return !ingredients.contains { $0.name.localizedCaseInsensitiveCompare(query) == .orderedSame }
    }

    private var groupedIngredients: [(IngredientType, [Ingredient])] {
        filteredIngredients.groupedByType()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(SearchTab.allCases, id: \.self) { tab in
                        Text(tab.localizedName).tag(tab)
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
            .onAppear { selectedTab = appState.preferredSearchTab }
            .onChange(of: appState.preferredSearchTab) { _, newTab in selectedTab = newTab }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cocktails, Ingredients…")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { appState.openSettings() } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cocktailGrid: some View {
        if cocktails.isEmpty {
            ContentUnavailableView(
                "No Cocktails",
                systemImage: "wineglass",
                description: Text("Add cocktails in the Cocktails tab.")
            )
            .padding(.top, 60)
        } else if filteredCocktails.isEmpty && !showCocktailSuggestion {
            ContentUnavailableView.search(text: query)
                .padding(.top, 60)
        } else {
            LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
                ForEach(filteredCocktails) { cocktail in
                    CocktailGridCell(cocktail: cocktail, onDelete: { appState.confirmDeleteCocktail(cocktail) }) {
                        appState.viewCocktail(cocktail)
                    }
                }
                if showCocktailSuggestion {
                    addCocktailCell(name: query) {
                        guard store.canAddMore(currentCount: cocktails.count) else {
                            appState.openPaywall()
                            return
                        }
                        var draft = CocktailDraft()
                        draft.name = query
                        appState.addCocktail(draft)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private var ingredientGrid: some View {
        if ingredients.isEmpty {
            ContentUnavailableView(
                "No Ingredients",
                systemImage: "leaf",
                description: Text("Add ingredients in the Ingredients tab.")
            )
            .padding(.top, 60)
        } else if filteredIngredients.isEmpty && !showIngredientSuggestion {
            ContentUnavailableView.search(text: query)
                .padding(.top, 60)
        } else if query.isEmpty {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(groupedIngredients, id: \.0) { type, items in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(type.localizedName)
                            .font(.title3.bold())
                            .fontDesign(.rounded)
                            .padding(.horizontal)

                        LazyVGrid(columns: GridColumns.ingredients, spacing: 10) {
                            ForEach(items) { ingredient in
                                IngredientGridCell(
                                    ingredient: ingredient,
                                    onEdit: { appState.editIngredient(ingredient) },
                                    onDelete: { appState.confirmDeleteIngredient(ingredient) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        } else {
            LazyVGrid(columns: GridColumns.ingredients, spacing: 10) {
                ForEach(filteredIngredients) { ingredient in
                    IngredientGridCell(
                        ingredient: ingredient,
                        onEdit: { appState.editIngredient(ingredient) },
                        onDelete: { appState.confirmDeleteIngredient(ingredient) }
                    )
                }
                if showIngredientSuggestion {
                    Button {
                        appState.addIngredient(named: query)
                    } label: {
                        addIngredientCell(name: query)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
    }
}

#Preview(traits: .sampleData) {
    SearchView()
        .environment(AppState())
}
