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
    var activeIngredientSheet: ActiveIngredientSheet?

    var cocktailGrouping: CocktailGrouping = .none {
        didSet { UserDefaults.standard.set(cocktailGrouping.rawValue, forKey: "cocktailGrouping") }
    }

    var preferredSearchTab: SearchTab {
        lastContentTab == .inventory ? .ingredients : .cocktails
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "cocktailGrouping"),
           let stored = CocktailGrouping(rawValue: raw) {
            _cocktailGrouping = stored
        }
    }
}
