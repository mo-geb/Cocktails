import Foundation

enum IngredientType: String, Codable, CaseIterable, Identifiable {
    case spirit
    case liqueur
    case fortifiedWine
    case syrup
    case juice
    case bitters
    case mixer
    case garnish
    case other

    /// Asset-based fallback image for devices without Apple Intelligence
    var imageName: String {
        switch self {
            case .spirit: return "Ingredient/dark_rum"
            case .liqueur: return "Ingredient/liqueur"
            case .syrup: return "Ingredient/syrup"
            case .juice: return "Ingredient/juice"
            case .bitters: return "Ingredient/bitters"
            case .mixer: return "Ingredient/soda_bottle"
            case .garnish: return "Ingredient/lime_wedge"
            default: return "Ingredient/fluid"
        }
    }

    var localizedName: String {
        switch self {
        case .spirit: return "Spirits"
        case .liqueur: return "Liqueurs"
        case .fortifiedWine: return "Fortified Wine"
        case .syrup: return "Syrups"
        case .juice: return "Juices"
        case .bitters: return "Bitters"
        case .mixer: return "Mixers"
        case .garnish: return "Garnishes"
        case .other: return "Other"
        }
    }

    var id: String { rawValue }
}
