enum RecipeSource: String, Codable, CaseIterable, Identifiable {
    case custom, ebsInter2023, shared
    
    var filePrefix: String {
        switch self {
        case .ebsInter2023: return "ebsInter2023"
        default: return ""
        }
    }
    
    var id: String { rawValue }
    
    var imageName: String {
        switch self {
        default: return ""
        }
    }
}
