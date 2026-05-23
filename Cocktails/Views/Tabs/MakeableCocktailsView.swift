import SwiftUI
import SwiftData

struct MakeableCocktailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var cocktails: [Cocktail]
    @State private var activeCocktailSheet: ActiveCocktailSheet?
    @State private var cocktailToDelete: Cocktail?

    private var makeableCocktails: [Cocktail] {
        cocktails
            .filter { !$0.coreIngredients.isEmpty && $0.coreIngredients.allSatisfy { $0.ingredient?.isStocked == true } }
            .sorted { $0.name < $1.name }
    }

    private var almostMakeableCocktails: [(cocktail: Cocktail, missing: String)] {
        cocktails
            .sorted { $0.name < $1.name }
            .compactMap { cocktail in
                let unstocked = cocktail.coreIngredients.filter { $0.ingredient?.isStocked != true }
                guard unstocked.count == 1, let missingName = unstocked.first?.ingredient?.localizedName else { return nil }
                return (cocktail: cocktail, missing: missingName)
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if makeableCocktails.isEmpty && almostMakeableCocktails.isEmpty {
                    ContentUnavailableView(
                        "Nothing to make",
                        systemImage: "wineglass",
                        description: Text("Stock ingredients in your inventory to see cocktails you can make.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 28) {
                            if !makeableCocktails.isEmpty {
                                section(title: "Ready to make") {
                                    LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
                                        ForEach(makeableCocktails) { cocktail in
                                            CocktailGridCell(cocktail: cocktail, onEdit: { activeCocktailSheet = .edit(cocktail) }, onDelete: { cocktailToDelete = cocktail }) {
                                                activeCocktailSheet = .view(cocktail)
                                            }
                                        }
                                    }
                                }
                            }

                            if !almostMakeableCocktails.isEmpty {
                                section(title: "Almost there") {
                                    LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
                                        ForEach(almostMakeableCocktails, id: \.cocktail.id) { item in
                                            CocktailGridCell(cocktail: item.cocktail, footerLabel: "Missing: \(item.missing)", onEdit: { activeCocktailSheet = .edit(item.cocktail) }, onDelete: { cocktailToDelete = item.cocktail }) {
                                                activeCocktailSheet = .view(item.cocktail)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("What can I make?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
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
            .sheet(item: $activeCocktailSheet) { sheet in
                switch sheet {
                case .view(let cocktail):
                    NavigationStack {
                        CocktailDetailView(cocktail: cocktail)
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                case .edit(let cocktail):
                    CocktailEditView(cocktail: cocktail)
                case .new(let draft):
                    CocktailEditView(draft: draft)
                }
            }
        }
    }

    @ViewBuilder
    private func section(title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .fontDesign(.rounded)
            content()
        }
    }
}

#Preview(traits: .sampleData) {
    MakeableCocktailsView()
}
