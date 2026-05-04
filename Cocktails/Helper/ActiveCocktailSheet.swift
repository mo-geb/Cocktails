import Foundation

enum ActiveCocktailSheet: Identifiable, Hashable {
    case new(CocktailDraft)
    case edit(Cocktail)
    case view(Cocktail)
    
    var id: String {
        switch self {
        case .new(_): return "new"
        case .edit(let c): return "edit-\(c.id)"
        case .view(let c): return "view-\(c.id)"
        }
    }
}
