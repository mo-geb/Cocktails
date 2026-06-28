import Foundation

enum CocktailGrouping: String, CaseIterable, Identifiable {
    case none, favourite, source, method

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .none:      return String(localized: "None",      comment: "Grouping — no grouping applied")
        case .favourite: return String(localized: "Favourite", comment: "Grouping by favourite status")
        case .source:    return String(localized: "Source",    comment: "Grouping by recipe source")
        case .method:    return String(localized: "Method",    comment: "Grouping by preparation method")
        }
    }

    var systemImage: String {
        switch self {
        case .none:      return "square.grid.2x2"
        case .method:    return "slider.horizontal.3"
        case .favourite: return "star"
        case .source:    return "books.vertical"
        }
    }

    func key(for cocktail: Cocktail) -> CocktailGroupKey {
        switch self {
        case .none:   return .allCocktails
        case .method: return CocktailGroupKey(name: cocktail.method.localizedName, imageName: cocktail.method.customImageName)
        case .source: return CocktailGroupKey(name: cocktail.source.localizedName, imageName: cocktail.source.imageName)
        case .favourite:
            return cocktail.isFavourite
                ? CocktailGroupKey(name: String(localized: "Favourites"), imageName: "Other/Favourite", sortRank: 0)
                : .allCocktails
        }
    }
}

struct CocktailGroupKey: Hashable {
    let name: String
    let imageName: String?
    /// Groups are ordered by rank first, then name — lets "Favourites" sort ahead
    /// of the rest without comparing against its localized display string.
    var sortRank = 1

    static var allCocktails: CocktailGroupKey {
        CocktailGroupKey(name: String(localized: "All Cocktails"), imageName: "Glass/Empty/martini")
    }
}
