import SwiftUI

enum ActiveCocktailSheet: Identifiable, Hashable {
    case new(CocktailDraft)
    case view(Cocktail)

    var id: String {
        switch self {
        case .new: return "new"
        case .view(let c): return "view-\(c.id)"
        }
    }
}

extension View {
    func cocktailSheet(_ sheet: Binding<ActiveCocktailSheet?>) -> some View {
        self.sheet(item: sheet) { active in
            NavigationStack {
                switch active {
                case .view(let cocktail):
                    CocktailDetailView(cocktail: cocktail)
                case .new(let draft):
                    CocktailEditView(draft: draft)
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}
