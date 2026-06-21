import SwiftUI

struct NewCocktailSheetView: View {
    let draft: CocktailDraft
    @Environment(\.dismiss) private var dismiss
    @State private var createdCocktail: Cocktail?

    var body: some View {
        NavigationStack {
            CocktailEditView(draft: draft, onSave: { cocktail in
                createdCocktail = cocktail
            })
            .navigationDestination(item: $createdCocktail) { cocktail in
                CocktailDetailView(cocktail: cocktail, onDone: { dismiss() })
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}
