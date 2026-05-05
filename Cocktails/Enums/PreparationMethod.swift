import Foundation

enum PreparationMethod: String, Codable, CaseIterable, Identifiable {
    case stir
    case shake
    case build
    case blend
    case roll

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .stir:  return String(localized: "Stir",  comment: "Preparation method")
        case .shake: return String(localized: "Shake", comment: "Preparation method")
        case .build: return String(localized: "Build", comment: "Preparation method")
        case .blend: return String(localized: "Blend", comment: "Preparation method")
        case .roll:  return String(localized: "Roll",  comment: "Preparation method")
        }
    }

    var customImageName: String {
        switch self {
        case .stir:  return "Method/stir"
        case .shake: return "Method/shake"
        default: return "Method/shake"
        }
    }
}
