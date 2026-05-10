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
    case shot
    case other
    
    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .rocks:     return String(localized: "Rocks",      comment: "Glass type")
        case .highball:  return String(localized: "Highball",   comment: "Glass type")
        case .martini:   return String(localized: "Martini",    comment: "Glass type")
        case .flute:     return String(localized: "Flute",      comment: "Glass type")
        case .copperMug: return String(localized: "Copper Mug", comment: "Glass type")
        case .hurricane: return String(localized: "Hurricane",  comment: "Glass type")
        case .tiki:      return String(localized: "Tiki",       comment: "Glass type")
        case .wine:      return String(localized: "Wine",       comment: "Glass type")
        case .shot:      return String(localized: "Shot",       comment: "Glass type")
        case .other:     return String(localized: "Other",      comment: "Glass type")
        }
    }

    var imageNameEmpty: String {
        switch self {
        case .highball:  return "Glass/Empty/highball"
        case .martini:   return "Glass/Empty/martini"
        case .rocks:     return "Glass/Empty/rocks"
        case .tiki:      return "Glass/Empty/tiki"
        case .wine:      return "Glass/Empty/wine"
        case .flute:     return "Glass/Empty/flute"
        case .copperMug: return "Glass/Empty/copper_mug"
        case .hurricane: return "Glass/Empty/hurricane"
        case .shot:      return "Glass/Empty/shot"
        case .other:     return "Glass/Empty/martini"
        }
    }

    var imageNameFilled: String {
        switch self {
        case .highball:  return "Glass/Filled/highball"
        case .martini:   return "Glass/Filled/martini"
        case .rocks:     return "Glass/Filled/rocks"
        case .tiki:      return "Glass/Filled/tiki"
        case .wine:      return "Glass/Filled/wine"
        case .flute:     return "Glass/Filled/flute"
        case .copperMug: return "Glass/Filled/copper_mug"
        case .hurricane: return "Glass/Filled/hurricane"
        case .shot:      return "Glass/Filled/shot"
        case .other:     return "Glass/Filled/martini"
        }
    }
}
