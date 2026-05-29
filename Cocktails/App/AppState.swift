import SwiftUI

@Observable
final class AppState {

    // MARK: - Navigation

    var selectedTab: ActiveTab = .cocktails {
        didSet { if oldValue != .search { lastContentTab = oldValue } }
    }
    private var lastContentTab: ActiveTab = .cocktails

    var preferredSearchTab: SearchTab {
        lastContentTab == .ingredients ? .ingredients : .cocktails
    }

    // MARK: - Presentation State

    var showSettings = false
    var showPaywall = false
    var showImportLibrary = false
    var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: Keys.hasSeenOnboarding)

    var activeCocktailSheet: ActiveCocktailSheet?
    var activeIngredientSheet: ActiveIngredientSheet?
    var cocktailToDelete: Cocktail?
    var ingredientToDelete: Ingredient?

    var pendingImportURL: URL?

    var cocktailGrouping: CocktailGrouping = .none {
        didSet { UserDefaults.standard.set(cocktailGrouping.rawValue, forKey: Keys.cocktailGrouping) }
    }

    // MARK: - Actions

    func openSettings() { showSettings = true }
    func openPaywall() { showPaywall = true }
    func openImportLibrary() { showImportLibrary = true }
    func dismissOnboarding() {
        showOnboarding = false
        UserDefaults.standard.set(true, forKey: Keys.hasSeenOnboarding)
    }

    func viewCocktail(_ cocktail: Cocktail) { activeCocktailSheet = .view(cocktail) }
    func editCocktail(_ cocktail: Cocktail) { activeCocktailSheet = .edit(cocktail) }
    func addCocktail(_ draft: CocktailDraft = CocktailDraft()) { activeCocktailSheet = .new(draft) }
    func confirmDeleteCocktail(_ cocktail: Cocktail) { cocktailToDelete = cocktail }

    func editIngredient(_ ingredient: Ingredient) { activeIngredientSheet = .edit(ingredient) }
    func addIngredient(named name: String? = nil) { activeIngredientSheet = name.map { .addWithName($0) } ?? .add }
    func confirmDeleteIngredient(_ ingredient: Ingredient) { ingredientToDelete = ingredient }

    // MARK: - Init

    init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.cocktailGrouping) {
            if let stored = CocktailGrouping(rawValue: raw) {
                _cocktailGrouping = stored
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.cocktailGrouping)
            }
        }
    }

    // MARK: - Private

    private enum Keys {
        static let cocktailGrouping = "cocktailGrouping"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }
}
