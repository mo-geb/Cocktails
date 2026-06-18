import SwiftUI
import SwiftData

struct IngredientTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @Query private var cocktails: [Cocktail]
    @State private var showMakeableCocktails = false
    @State private var selectAllHapticTrigger = false
    
    private var groupedIngredients: [(IngredientType, [Ingredient])] {
        ingredients
            .sorted { $0.isStocked && !$1.isStocked }
            .groupedByType()
    }
    
    private var allStocked: Bool {
        ingredients.allSatisfy { $0.isStocked }
    }
    
    private var makeableCount: Int {
        cocktails.count(where: \.isMakeable)
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Ingredients")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showMakeableCocktails) { MakeableCocktailsView() }
                .sensoryFeedback(.impact(weight: .medium), trigger: selectAllHapticTrigger)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if ingredients.isEmpty {
            ContentUnavailableView {
                Label("No Ingredients", systemImage: "leaf")
            } description: {
                Text("Import the ingredient library or tap + to add ingredients manually.")
            } actions: {
                Button("Import Library") { appState.openImportLibrary() }
                    .buttonStyle(.glassProminent)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    makeableCocktailsCard

                    ForEach(groupedIngredients, id: \.0) { type, items in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(type.localizedName)
                                .sectionTitleStyle()
                                .padding(.horizontal)

                            LazyVGrid(columns: GridColumns.ingredients, spacing: 10) {
                                ForEach(items) { ingredient in
                                    IngredientGridCell(
                                        ingredient: ingredient,
                                        onShowCocktails: { appState.showCocktails(for: ingredient) },
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
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { appState.openSettings() } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    let newValue = !allStocked
                    for ingredient in ingredients { ingredient.isStocked = newValue }
                    selectAllHapticTrigger.toggle()
                } label: {
                    Label(allStocked ? "Deselect All" : "Select All",
                          systemImage: allStocked ? "minus.circle" : "checkmark.circle")
                }
            } label: {
                Label("More", systemImage: "ellipsis")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button { appState.addIngredient() } label: {
                Label("Add Ingredient", systemImage: "plus")
            }
        }
    }

    private var makeableCocktailsCard: some View {
        Button { showMakeableCocktails = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "wineglass")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.purple.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

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
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 1)
            }
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .sampleData) {
    IngredientTab()
        .environment(AppState())
}

#Preview("Empty") {
    IngredientTab()
        .environment(AppState())
        .modelContainer(for: Ingredient.self, inMemory: true)
}
