import SwiftUI
import SwiftData

struct InventoryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @Query private var cocktails: [Cocktail]
    @State private var showMakeableCocktails = false

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var groupedIngredients: [(IngredientType, [Ingredient])] {
        let groups = Dictionary(grouping: ingredients) { $0.type }
        return IngredientType.allCases.compactMap { type in
            guard let items = groups[type], !items.isEmpty else { return nil }
            let sorted = items.sorted { $0.isStocked && !$1.isStocked }
            return (type, sorted)
        }
    }

    private var allStocked: Bool {
        ingredients.allSatisfy { $0.isStocked }
    }

    private var makeableCount: Int {
        cocktails.filter { cocktail in
            let core = cocktail.ingredients?.filter { $0.role == .core } ?? []
            return !core.isEmpty && core.allSatisfy { $0.ingredient?.isStocked == true }
        }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    makeableCocktailsCard

                    ForEach(groupedIngredients, id: \.0) { type, items in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(type.localizedName)
                                .font(.title3.bold())
                                .fontDesign(.rounded)
                                .padding(.horizontal)

                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(items) { ingredient in
                                    IngredientGridCell(ingredient: ingredient) {
                                        appState.activeIngredientSheet = .edit(ingredient)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inventory")
            .toolbar {
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
            .sheet(isPresented: $showMakeableCocktails) { MakeableCocktailsView() }
        }
    }

    private var makeableCocktailsCard: some View {
        Button { showMakeableCocktails = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "wineglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(makeableCount == 0 ? "Nothing to make yet" : "\(makeableCount) cocktail\(makeableCount == 1 ? "" : "s") ready to make")
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
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal)
        }
        .buttonStyle(CardPressStyle())
    }
}

#Preview {
    InventoryTab()
        .environment(AppState())
        .modelContainer(PreviewSampleData.container)
}
