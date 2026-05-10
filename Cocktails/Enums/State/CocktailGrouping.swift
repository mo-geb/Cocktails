import Foundation

enum CocktailGrouping: String, CaseIterable, Identifiable {
    case none
    case glass
    case method
    case ice
    case favourite

    var id: String { self.rawValue }

    var localizedName: String {
        switch self {
        case .none:      return String(localized: "None",      comment: "Grouping — no grouping applied")
        case .glass:     return String(localized: "Glass",     comment: "Grouping by glass type")
        case .method:    return String(localized: "Method",    comment: "Grouping by preparation method")
        case .ice:       return String(localized: "Ice",       comment: "Grouping by ice type")
        case .favourite: return String(localized: "Favourite", comment: "Grouping by favourite status")
        }
    }

    var systemImage: String {
        switch self {
        case .none:      return "square.grid.2x2"
        case .glass:     return "wineglass"
        case .method:    return "slider.horizontal.3"
        case .ice:       return "snowflake"
        case .favourite: return "star"
        }
    }
}
