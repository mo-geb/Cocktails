import SwiftUI

enum ActiveIngredientSheet: Identifiable {
    case add
    case addWithName(String)
    case edit(Ingredient)

    var id: String {
        switch self {
        case .add: return "add"
        case .addWithName(let name): return "add-\(name)"
        case .edit(let i): return "edit-\(i.id)"
        }
    }

    @ViewBuilder var contentView: some View {
        switch self {
        case .add: IngredientEditView()
        case .addWithName(let name): IngredientEditView(suggestedName: name)
        case .edit(let i): IngredientEditView(ingredient: i)
        }
    }
}
