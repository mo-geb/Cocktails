import Foundation

enum IngredientType: String, Codable, CaseIterable, Identifiable {
    case spirit, liqueur, fortifiedWine, syrup, juice, bitters, mixer, fruit, herb, spice, vegetable, other

    var imageName: String {
        switch self {
        case .spirit:           return "Ingredient/vodka"
        case .liqueur:          return "Ingredient/peach_liqueur"
        case .fortifiedWine:    return "Ingredient/vermouth"
        case .syrup:            return "Ingredient/sugar_syrup"
        case .juice:            return "Ingredient/orange_juice"
        case .bitters:          return "Ingredient/bitters"
        case .mixer:            return "Ingredient/mixer"
        case .fruit:            return "Ingredient/lime_wedge"
        case .herb:             return "Ingredient/mint_leaf"
        case .spice:            return "Ingredient/black_pepper"
        case .vegetable:        return "Ingredient/celery_stick"
        default:                return "Ingredient/fluid"
        }
    }

    var localizedName: String {
        switch self {
        case .spirit:           return String(localized: "Spirits")
        case .liqueur:          return String(localized: "Liqueurs")
        case .fortifiedWine:    return String(localized: "Fortified Wine")
        case .syrup:            return String(localized: "Syrups")
        case .juice:            return String(localized: "Juices")
        case .bitters:          return String(localized: "Bitters")
        case .mixer:            return String(localized: "Mixers")
        case .fruit:            return String(localized: "Fruits")
        case .herb:             return String(localized: "Herbs")
        case .spice:            return String(localized: "Spices")
        case .vegetable:        return String(localized: "Vegetables")
        case .other:            return String(localized: "Other")
        }
    }

    var id: String { rawValue }
}
