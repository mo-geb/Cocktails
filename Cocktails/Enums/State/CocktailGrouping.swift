import Foundation

enum CocktailGrouping: String, CaseIterable, Identifiable {
    case none = "None"
    case glass = "Glass"
    case method = "Method"
    case ice = "Ice"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .none: return "square.grid.2x2"
        case .glass: return "wineglass"
        case .method: return "slider.horizontal.3"
        case .ice: return "snowflake"
        }
    }
}
