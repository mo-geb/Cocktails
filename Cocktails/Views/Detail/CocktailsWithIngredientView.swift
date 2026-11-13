import SwiftUI
import SwiftData

struct CocktailsWithIngredientView: View {
    let ingredient: Ingredient

    @Environment(\.dismiss) private var dismiss
    @State private var viewedCocktail: Cocktail?
    @State private var cocktailToDelete: Cocktail?

    private var cocktails: [Cocktail] { ingredient.cocktails }

    var body: some View {
        NavigationStack {
            Group {
                if cocktails.isEmpty {
                    ContentUnavailableView(
                        "Not Used Yet",
                        systemImage: "wineglass",
                        description: Text("No cocktails use \(ingredient.localizedName).")
                    )
                } else {
                    ScrollView {
                        AdaptiveGrid(.cocktails) {
                            ForEach(cocktails) { cocktail in
                                CocktailGridCell(cocktail: cocktail, onDelete: { cocktailToDelete = cocktail }) {
                                    viewedCocktail = cocktail
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle(ingredient.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
            .cocktailDeletionDialog($cocktailToDelete)
            .navigationDestination(item: $viewedCocktail) { cocktail in
                CocktailDetailView(cocktail: cocktail)
            }
        }
    }
}

#Preview(traits: .sampleData) {
    let ingredient = try! PreviewSampleData.container.mainContext.fetch(FetchDescriptor<Ingredient>()).first!
    CocktailsWithIngredientView(ingredient: ingredient)
}
