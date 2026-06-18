import SwiftUI
import SwiftData

struct CocktailsWithIngredientView: View {
    let ingredient: Ingredient

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewedCocktail: Cocktail?
    @State private var cocktailToDelete: Cocktail?
    @Namespace private var zoomNamespace

    private var cocktails: [Cocktail] { ingredient.cocktails }

    var body: some View {
        NavigationStack {
            Group {
                if cocktails.isEmpty {
                    ContentUnavailableView(
                        "Not used yet",
                        systemImage: "wineglass",
                        description: Text("No cocktails use \(ingredient.localizedName).")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
                            ForEach(cocktails) { cocktail in
                                CocktailGridCell(cocktail: cocktail, onDelete: { cocktailToDelete = cocktail }) {
                                    viewedCocktail = cocktail
                                }
                                .matchedTransitionSource(id: cocktail.id, in: zoomNamespace)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(ingredient.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete \"\(cocktailToDelete?.name ?? "")\"?",
                isPresented: .init(presence: $cocktailToDelete),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let c = cocktailToDelete { modelContext.delete(c) }
                    cocktailToDelete = nil
                }
            }
            .cocktailZoomDestination($viewedCocktail, in: zoomNamespace)
        }
    }
}

#Preview(traits: .sampleData) {
    let ingredient = try! PreviewSampleData.container.mainContext.fetch(FetchDescriptor<Ingredient>()).first!
    CocktailsWithIngredientView(ingredient: ingredient)
}
