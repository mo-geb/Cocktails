import SwiftUI
import SwiftData

struct IngredientTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @Query private var cocktails: [Cocktail]
    @State private var showMakeableCocktails = false
    
    private var groupedIngredients: [(IngredientType, [Ingredient])] {
        ingredients
            .sorted { $0.isStocked && !$1.isStocked }
            .groupedByType()
    }
    
    private var allStocked: Bool {
        ingredients.allSatisfy { $0.isStocked }
    }
    
    private var makeableCount: Int {
        cocktails.filter { !$0.coreIngredients.isEmpty && $0.coreIngredients.allSatisfy { $0.ingredient?.isStocked == true } }.count
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Ingredients")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showMakeableCocktails) { MakeableCocktailsView() }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if ingredients.isEmpty {
            ContentUnavailableView(
                "No Ingredients",
                systemImage: "leaf",
                description: Text("Tap + to add ingredients to your bar.")
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    makeableCocktailsCard
                    
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
                                        onEdit: { appState.activeIngredientSheet = .edit(ingredient) },
                                        onDelete: { appState.ingredientToDelete = ingredient }
                                    )
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
        ToolbarItem(placement: .topBarLeading) {
            Button { appState.showSettings = true } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    let newValue = !allStocked
                    for ingredient in ingredients { ingredient.isStocked = newValue }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Label(allStocked ? "Deselect All" : "Select All",
                          systemImage: allStocked ? "minus.circle" : "checkmark.circle")
                }
            } label: {
                Label("More", systemImage: "ellipsis")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button { appState.activeIngredientSheet = .add } label: {
                Label("Add Ingredient", systemImage: "plus")
            }
        }
    }

    private var makeableCocktailsCard: some View {
        Button { showMakeableCocktails = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "wineglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(makeableCount == 0 ? "Nothing to make yet" : "\(makeableCount) cocktails ready to make")
                        .font(.subheadline.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    Text("Based on your stocked ingredients")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal)
        }
        .buttonStyle(CardPressStyle())
    }
}

#Preview(traits: .sampleData) {
    IngredientTab()
        .environment(AppState())
}
