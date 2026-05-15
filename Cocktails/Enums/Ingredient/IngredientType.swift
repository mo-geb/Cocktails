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
        case .spirit:           return "Spirits"
        case .liqueur:          return "Liqueurs"
        case .fortifiedWine:    return "Fortified Wine"
        case .syrup:            return "Syrups"
        case .juice:            return "Juices"
        case .bitters:          return "Bitters"
        case .mixer:            return "Mixers"
        case .fruit:            return "Fruits"
        case .herb:             return "Herbs"
        case .spice:            return "Spices"
        case .vegetable:        return "Vegetables"
        case .other:            return "Other"
        }
    }

    var id: String { rawValue }
}
