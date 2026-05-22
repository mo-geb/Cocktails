import Foundation

enum SearchTab: String, CaseIterable {
    case cocktails, ingredients

    var localizedName: String {
        switch self {
        case .cocktails:   return String(localized: "Cocktails",   comment: "Search tab")
        case .ingredients: return String(localized: "Ingredients", comment: "Search tab")
        }
    }
}
