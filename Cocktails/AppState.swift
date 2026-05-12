import SwiftUI

@Observable
final class AppState {
    var selectedTab: ActiveTab = .cocktails
    var showSettings = false
    var activeCocktailSheet: ActiveCocktailSheet?
    var cocktailToDelete: Cocktail?

    var cocktailGrouping: CocktailGrouping = .none {
        didSet { UserDefaults.standard.set(cocktailGrouping.rawValue, forKey: "cocktailGrouping") }
    }

    var preferredSearchTab: SearchTab {
        selectedTab == .inventory ? .ingredients : .cocktails
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "cocktailGrouping"),
           let stored = CocktailGrouping(rawValue: raw) {
            _cocktailGrouping = stored
        }
    }
}
