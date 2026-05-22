import SwiftUI

@Observable
final class AppState {
    var selectedTab: ActiveTab = .cocktails {
        didSet { if oldValue != .search { lastContentTab = oldValue } }
    }
    private var lastContentTab: ActiveTab = .cocktails

    var showSettings = false
    var showPaywall = false
    var activeCocktailSheet: ActiveCocktailSheet?
    var cocktailToDelete: Cocktail?
    var ingredientToDelete: Ingredient?
    var activeIngredientSheet: ActiveIngredientSheet?

    var pendingImportURL: URL?

    private static let cocktailGroupingKey = "cocktailGrouping"

    var cocktailGrouping: CocktailGrouping = .none {
        didSet { UserDefaults.standard.set(cocktailGrouping.rawValue, forKey: Self.cocktailGroupingKey) }
    }

    var preferredSearchTab: SearchTab {
        lastContentTab == .ingredients ? .ingredients : .cocktails
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.cocktailGroupingKey) {
            if let stored = CocktailGrouping(rawValue: raw) {
                _cocktailGrouping = stored
            } else {
                UserDefaults.standard.removeObject(forKey: Self.cocktailGroupingKey)
            }
        }
    }
}
