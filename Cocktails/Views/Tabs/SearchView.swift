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
    @State private var viewedCocktail: Cocktail?
    @Namespace private var zoomNamespace


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

    var body: some View {
        NavigationStack {
            // A hand-placed picker rather than `.searchScopes`: on iOS 27 the system
            // scope bar disappears when search is re-entered from the search tab.
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
            .cocktailZoomDestination($viewedCocktail, in: zoomNamespace)
            .onAppear { selectedTab = appState.preferredSearchTab }
            .onChange(of: appState.preferredSearchTab) { _, newTab in selectedTab = newTab }
            // No explicit placement: inside a `.search` role tab the system puts the
            // field in the tab bar. Kept here rather than on the TabView, where it
            // leaks a stray search field into the previous tab after cancelling.
            .searchable(text: $query, prompt: "Cocktails, Ingredients…")
            // With `.searchTabSelection` this page is only ever shown with search active,
            // which hides the navigation bar. Hiding it up front stops the title from
            // flashing before search activates. The title still labels the back button.
            .toolbarVisibility(.hidden, for: .navigationBar)
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
            AdaptiveGrid(.cocktails) {
                ForEach(filteredCocktails) { cocktail in
                    CocktailGridCell(cocktail: cocktail, onDelete: { appState.confirmDeleteCocktail(cocktail) }) {
                        viewedCocktail = cocktail
                    }
                    .matchedTransitionSource(id: cocktail.id, in: zoomNamespace)
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
        } else {
            AdaptiveGrid(.ingredients) {
                ForEach(filteredIngredients) { ingredient in
                    IngredientGridCell(
                        ingredient: ingredient,
                        onShowCocktails: { appState.showCocktails(for: ingredient) },
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
