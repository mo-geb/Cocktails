import Foundation

enum GlassType: String, Codable, CaseIterable, Identifiable {
    case rocks
    case highball
    case martini
    case flute
    case copperMug
    case hurricane
    case tiki
    case wine
    case other
    
    var id: String { rawValue }
    
    var imageNameEmpty: String {
        switch self {
        case .highball: return "glass_highball_empty"
        case .martini: return "glass_martini_empty"
        case .rocks: return "glass_rocks_empty"
        case .tiki: return "glass_tiki_empty"
        case .wine: return "glass_wine_empty"
        case .flute: return "glass_flute_empty"
        case .copperMug: return "glass_copper_mug_empty"
        case .hurricane: return "glass_hurricane_empty"
        default: return "glass_martini_empty"
        }
    }
    
    var imageNameFilled: String {
        switch self {
        case .highball: return "glass_highball_filled"
        case .martini: return "glass_martini_filled"
        case .rocks: return "glass_rocks_filled"
        case .tiki: return "glass_tiki_filled"
        case .wine: return "glass_wine_filled"
        case .flute: return "glass_flute_filled"
        case .copperMug: return "glass_copper_mug_filled"
        case .hurricane: return "glass_hurricane_filled"
        default: return "glass_martini_filled"
        }
    }
}
