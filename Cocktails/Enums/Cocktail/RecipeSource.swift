import Foundation
enum RecipeSource: String, Codable, CaseIterable, Identifiable {
    case custom, ebsInter2023, clutterfree, shared

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .custom: return String(localized: "Custom", comment: "Recipe source — user created")
        case .ebsInter2023: return String(localized: "EBS", comment: "Recipe source — book title")
        case .clutterfree: return String(localized: "ClutterFree", comment: "Recipe source — Selection")
        case .shared: return String(localized: "Shared", comment: "Recipe source — shared recipe")
        }
    }

    var filePrefix: String {
        switch self {
        case .ebsInter2023: return "ebsInter2023"
        case .clutterfree: return "clutterfree"
        default: return ""
        }
    }

    var imageName: String {
        switch self {
        case .ebsInter2023: return "Source/ebs"
        default: return "Source/custom"
        }
    }
}
