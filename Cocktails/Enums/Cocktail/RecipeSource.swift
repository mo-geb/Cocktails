import Foundation
enum RecipeSource: String, Codable, CaseIterable, Identifiable {
    case custom, clutterfree, ebsInter2023, ibaUnforgettables, shared

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .custom:               return String(localized: "Custom", comment: "Recipe source — user created")
        case .ebsInter2023:         return String(localized: "EBS", comment: "Recipe source — book title")
        case .clutterfree:          return String(localized: "ClutterFree", comment: "Recipe source — Selection")
        case .ibaUnforgettables:    return String(localized: "IBA Unforgettables", comment: "Recipe source — IBA classic cocktails")
        case .shared:               return String(localized: "Shared", comment: "Recipe source — shared recipe")
        }
    }

    var filePrefix: String {
        switch self {
        case .ebsInter2023:         return "ebsInter2023"
        case .clutterfree:          return "clutterfree"
        case .ibaUnforgettables:    return "ibaUnforgettables"
        default: return ""
        }
    }

    var imageName: String {
        switch self {
        case .ebsInter2023:         return "Source/ebs"
        case .ibaUnforgettables:    return "Source/iba"
        case .clutterfree:          return "Source/clutterfree"
        default: return "Source/custom"
        }
    }

    var localizedDescription: String {
        switch self {
        case .ebsInter2023:
            return String(localized: "The European Bartender School is globally recognised for providing top-quality bartender courses designed by the world-leading experts. Their International Bartender Course includes learning these 66 cocktails by heart.", comment: "Recipe source description — EBS")
        case .clutterfree:
            return String(localized: "Favourite recipes and personal variations. Where a recipe comes from the web, the source is linked in the notes.", comment: "Recipe source description — ClutterFree")
        case .ibaUnforgettables:
            return String(localized: "IBA Unforgettables are a curated list of timeless, classic cocktail recipes established by the International Bartenders Association.", comment: "Recipe source description — IBA Unforgettables")
        case .custom, .shared:
            return ""
        }
    }

    var sourceURL: URL? {
        switch self {
        case .ebsInter2023:         return URL(string: "https://www.barschool.net/")
        case .ibaUnforgettables:    return URL(string: "https://iba-world.com/cocktails/the-unforgettables/")
        case .clutterfree, .custom, .shared: return nil
        }
    }
}
