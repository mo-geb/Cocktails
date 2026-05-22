import Foundation

enum CocktailGrouping: String, CaseIterable, Identifiable {
    case none, favourite, source, method

    var id: String { self.rawValue }

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
}
