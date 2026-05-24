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
        case .bitters:          return "Ingredient/angostura_bitters"
        case .mixer:            return "Ingredient/mixer"
        case .fruit:            return "Ingredient/Type/fruit"
        case .herb:             return "Ingredient/Type/herb"
        case .spice:            return "Ingredient/Type/spice"
        case .vegetable:        return "Ingredient/Type/vegetable"
        case .other:            return "Ingredient/Type/fluid"
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
