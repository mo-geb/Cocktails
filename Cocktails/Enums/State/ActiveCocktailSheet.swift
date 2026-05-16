import SwiftUI

enum ActiveCocktailSheet: Identifiable, Hashable {
    case new(CocktailDraft)
    case edit(Cocktail)
    case view(Cocktail)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let c): return "edit-\(c.id)"
        case .view(let c): return "view-\(c.id)"
        }
    }

    @ViewBuilder var contentView: some View {
        switch self {
        case .new(let draft): CocktailEditView(draft: draft)
        case .edit(let c): CocktailEditView(cocktail: c)
        case .view(let c): CocktailDetailView(cocktail: c)
        }
    }
}
