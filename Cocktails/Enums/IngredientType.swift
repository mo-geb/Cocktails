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
            case .spirit: return "ingredient_dark_rum"
            case .liqueur: return "ingredient_liqueur"
            case .syrup: return "ingredient_syrup"
            case .juice: return "ingredient_juice"
            case .bitters: return "ingredient_bitters"
            case .mixer: return "ingredient_soda_bottle"
            case .garnish: return "ingredient_lime_wedge"
            default: return "ingredient_fluid"
        }
    }
    
    var id: String { rawValue }
}
