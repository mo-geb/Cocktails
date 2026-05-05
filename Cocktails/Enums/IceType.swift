import Foundation

enum IceType: String, Codable, CaseIterable, Identifiable {
    case cubed
    case crushed
    case clearBlock
    case none
    
    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .cubed:      return String(localized: "Cubed",       comment: "Ice type")
        case .crushed:    return String(localized: "Crushed",     comment: "Ice type")
        case .clearBlock: return String(localized: "Clear Block", comment: "Ice type")
        case .none:       return String(localized: "No Ice",        comment: "Ice type — no ice")
        }
    }

    var imageName: String {
        switch self {
        case .cubed: return "Ice/cubed"
        case .crushed: return "Ice/crushed"
        case .clearBlock: return "Ice/clear"
        case .none: return "Ice/none"
        }
    }
}
