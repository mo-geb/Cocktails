import Foundation

enum IngredientType: String, Codable, CaseIterable, Identifiable {
    case spirit
    case liqueur
    case fortifiedWine
    case syrup
    case juice
    case bitters
    case mixer
    case fruit
    case herb
    case spice
    case vegetable
    case other

    var imageName: String {
        switch self {
            case .spirit: return "Ingredient/dark_rum"
            case .liqueur: return "Ingredient/liqueur"
            case .syrup: return "Ingredient/syrup"
            case .juice: return "Ingredient/juice"
            case .bitters: return "Ingredient/bitters"
            case .mixer: return "Ingredient/soda_bottle"
            case .fruit: return "Ingredient/lime_wedge"
            case .herb: return "Ingredient/mint_leaf"
            case .spice: return "Ingredient/black_pepper"
            case .vegetable: return "Ingredient/celery_stick"
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
        case .fruit: return "Fruits"
        case .herb: return "Herbs"
        case .spice: return "Spices"
        case .vegetable: return "Vegetables"
        case .other: return "Other"
        }
    }

    var id: String { rawValue }
}
