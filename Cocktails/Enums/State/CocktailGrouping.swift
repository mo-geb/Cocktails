import Foundation

enum CocktailGrouping: String, CaseIterable, Identifiable {
    case none, favourite, source, glass, method, base

    var id: String { self.rawValue }

    var localizedName: String {
        switch self {
        case .none:      return String(localized: "None",      comment: "Grouping — no grouping applied")
        case .favourite: return String(localized: "Favourite", comment: "Grouping by favourite status")
        case .source:    return String(localized: "Source",    comment: "Grouping by recipe source")
        case .glass:     return String(localized: "Glass",     comment: "Grouping by glass type")
        case .method:    return String(localized: "Method",    comment: "Grouping by preparation method")
        case .base:      return String(localized: "Base",      comment: "Grouping by base spirit")
        }
    }

    var systemImage: String {
        switch self {
        case .none:      return "square.grid.2x2"
        case .glass:     return "wineglass"
        case .method:    return "slider.horizontal.3"
        case .favourite: return "star"
        case .source:    return "books.vertical"
        case .base:      return "drop.fill"
        }
    }
}
