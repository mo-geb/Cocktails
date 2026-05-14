import Foundation
enum RecipeSource: String, Codable, CaseIterable, Identifiable {
    case custom, ebsInter2023, clutterfree, ibaUnforgettables, shared

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .custom: return String(localized: "Custom", comment: "Recipe source — user created")
        case .ebsInter2023: return String(localized: "EBS", comment: "Recipe source — book title")
        case .clutterfree: return String(localized: "ClutterFree", comment: "Recipe source — Selection")
        case .ibaUnforgettables: return String(localized: "IBA Unforgettables", comment: "Recipe source — IBA classic cocktails")
        case .shared: return String(localized: "Shared", comment: "Recipe source — shared recipe")
        }
    }

    var filePrefix: String {
        switch self {
        case .ebsInter2023: return "ebsInter2023"
        case .clutterfree: return "clutterfree"
        case .ibaUnforgettables: return "ibaUnforgettables"
        default: return ""
        }
    }

    var imageName: String {
        switch self {
        case .ebsInter2023: return "Source/ebs"
        case .ibaUnforgettables: return "Source/iba"
        default: return "Source/custom"
        }
    }
}
