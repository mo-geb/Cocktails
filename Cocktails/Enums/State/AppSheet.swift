import SwiftUI

enum AppSheet: Identifiable {
    case settings
    case importLibrary
    case receivedRecipes(URL)
    case ingredientSheet(ActiveIngredientSheet)
    case cocktailsWithIngredient(Ingredient)
    case newCocktail(CocktailDraft)

    var id: String {
        switch self {
        case .settings: return "settings"
        case .importLibrary: return "importLibrary"
        case .receivedRecipes(let url): return "receivedRecipes-\(url.absoluteString)"
        case .ingredientSheet(let sheet): return "ingredientSheet-\(sheet.id)"
        case .cocktailsWithIngredient(let ingredient): return "cocktailsWithIngredient-\(ingredient.id)"
        case .newCocktail: return "newCocktail"
        }
    }
}
