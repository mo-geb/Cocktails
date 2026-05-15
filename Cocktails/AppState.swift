import SwiftUI

@Observable
final class AppState {
    var selectedTab: ActiveTab = .cocktails {
        didSet { if oldValue != .search { lastContentTab = oldValue } }
    }
    private var lastContentTab: ActiveTab = .cocktails

    var showSettings = false
    var activeCocktailSheet: ActiveCocktailSheet?
    var cocktailToDelete: Cocktail?
    var ingredientToDelete: Ingredient?
    var activeIngredientSheet: ActiveIngredientSheet?

    var pendingImportURL: URL?

    var cocktailGrouping: CocktailGrouping = .none {
        didSet { UserDefaults.standard.set(cocktailGrouping.rawValue, forKey: "cocktailGrouping") }
    }

    var preferredSearchTab: SearchTab {
        lastContentTab == .ingredients ? .ingredients : .cocktails
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "cocktailGrouping"),
           let stored = CocktailGrouping(rawValue: raw) {
            _cocktailGrouping = stored
        }
    }
}
