import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Cocktail.name) private var cocktails: [Cocktail]
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]

    @State private var query = ""
    @State private var selectedTab: SearchTab = .cocktails

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
        guard !query.isEmpty else { return cocktails }
        return cocktails.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var filteredIngredients: [Ingredient] {
        guard !query.isEmpty else { return ingredients }
        return ingredients.filter { $0.name.localizedCaseInsensitiveContains(query) }
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
            .onAppear { selectedTab = appState.preferredSearchTab }
            .onChange(of: appState.preferredSearchTab) { _, newTab in selectedTab = newTab }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cocktails, Ingredients…")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { appState.showSettings = true } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cocktailGrid: some View {
        if filteredCocktails.isEmpty && !showCocktailSuggestion {
            ContentUnavailableView.search(text: query)
                .padding(.top, 60)
        } else {
            LazyVGrid(columns: cocktailColumns, spacing: 12) {
                ForEach(filteredCocktails) { cocktail in
                    CocktailGridCell(cocktail: cocktail, onEdit: { appState.activeCocktailSheet = .edit(cocktail) }, onDelete: { appState.cocktailToDelete = cocktail }) {
                        appState.activeCocktailSheet = .view(cocktail)
                    }
                }
                if showCocktailSuggestion {
                    cocktailAddCard(name: query) {
                        var draft = CocktailDraft()
                        draft.name = query
                        appState.activeCocktailSheet = .new(draft)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private var ingredientGrid: some View {
        if filteredIngredients.isEmpty && !showIngredientSuggestion {
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

                        LazyVGrid(columns: ingredientColumns, spacing: 10) {
                            ForEach(items) { ingredient in
                                IngredientGridCell(ingredient: ingredient) { appState.activeIngredientSheet = .edit(ingredient) }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        } else {
            LazyVGrid(columns: ingredientColumns, spacing: 10) {
                ForEach(filteredIngredients) { ingredient in
                    IngredientGridCell(ingredient: ingredient)
                }
                if showIngredientSuggestion {
                    Button {
                        appState.activeIngredientSheet = .addWithName(query)
                    } label: {
                        ingredientAddCellLabel(name: query)
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
