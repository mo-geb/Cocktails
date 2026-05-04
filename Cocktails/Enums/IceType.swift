import Foundation

enum IceType: String, Codable, CaseIterable, Identifiable {
    case cubed
    case crushed
    case clearBlock
    case none
    
    var id: String { rawValue }
    
    var imageName: String {
        switch self {
        case .cubed: return "ice_cubed"
        case .crushed: return "ice_crushed"
        case .clearBlock: return "ice_clear"
        case .none: return "ice_none"
        }
    }
}
