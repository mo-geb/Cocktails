import SwiftUI
import SwiftData

struct InventoryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @State private var showSettings = false
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
            return (type, items)
        }
    }

    private var allStocked: Bool {
        ingredients.allSatisfy { $0.isStocked }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(groupedIngredients, id: \.0) { type, items in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(type.localizedName)
                                .font(.title3.bold())
                                .fontDesign(.rounded)
                                .padding(.horizontal)

                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(items) { ingredient in
                                    IngredientGridCell(ingredient: ingredient)
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
                    Button { showSettings = true } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(allStocked ? "Deselect All" : "Select All") {
                        let newValue = !allStocked
                        for ingredient in ingredients {
                            ingredient.isStocked = newValue
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showMakeableCocktails = true } label: {
                        Label("What can I make?", systemImage: "wineglass")
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showMakeableCocktails) { MakeableCocktailsView() }
        }
    }
}

#Preview {
    InventoryTab()
        .modelContainer(PreviewSampleData.container)
}
