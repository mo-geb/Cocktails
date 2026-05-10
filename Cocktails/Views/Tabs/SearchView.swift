import SwiftUI
import SwiftData

enum SearchTab: String, CaseIterable {
    case cocktails = "Cocktails"
    case ingredients = "Ingredients"
}

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cocktail.name) private var cocktails: [Cocktail]
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]

    let preferredTab: SearchTab

    @State private var query = ""
    @State private var selectedTab: SearchTab
    @State private var activeCocktailSheet: ActiveCocktailSheet?
    @State private var showSettings = false
    @State private var suggestionSheet: SuggestionSheet?
    @State private var cocktailToDelete: Cocktail?

    init(preferredTab: SearchTab = .cocktails) {
        self.preferredTab = preferredTab
        self._selectedTab = State(initialValue: preferredTab)
    }

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
            .onAppear { selectedTab = preferredTab }
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
                    NavigationStack { CocktailDetailView(cocktail: c) }
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                default: EmptyView()
                }
            }
            .sheet(item: $suggestionSheet) { suggestionSheetView($0) }
            .confirmationDialog(
                "Delete \"\(cocktailToDelete?.name ?? "")\"?",
                isPresented: Binding(get: { cocktailToDelete != nil }, set: { if !$0 { cocktailToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let c = cocktailToDelete { modelContext.delete(c) }
                    cocktailToDelete = nil
                }
            }
        }
    }

    @ViewBuilder
    private func suggestionSheetView(_ sheet: SuggestionSheet) -> some View {
        switch sheet {
        case .cocktail(let name):
            let draft = { var d = CocktailDraft(); d.name = name; return d }()
            NavigationStack { CocktailEditView(draft: draft) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        case .ingredient(let name):
            NavigationStack { IngredientEditView(suggestedName: name) }
                .presentationDetents([.medium])
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
                    CocktailGridCell(cocktail: cocktail, onDelete: { cocktailToDelete = cocktail }) {
                        activeCocktailSheet = .view(cocktail)
                    }
                }
                if showCocktailSuggestion {
                    cocktailAddCard(name: query) {
                        suggestionSheet = .cocktail(query)
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
                if showIngredientSuggestion {
                    Button {
                        suggestionSheet = .ingredient(query)
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

private enum SuggestionSheet: Identifiable {
    case cocktail(String)
    case ingredient(String)
    var id: String {
        switch self {
        case .cocktail(let name): "cocktail-\(name)"
        case .ingredient(let name): "ingredient-\(name)"
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(PreviewSampleData.container)
}
