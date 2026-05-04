import Foundation

enum PreparationMethod: String, Codable, CaseIterable, Identifiable {
    case stir
    case shake
    case build
    case blend
    case roll
    
    var id: String { rawValue }
    
    var customImageName: String {
        switch self {
        case .shake: return "method_shake"
        default: return "method_shake"
        }
    }
}
