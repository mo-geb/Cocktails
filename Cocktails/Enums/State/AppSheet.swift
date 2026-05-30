import SwiftUI

enum AppSheet: Identifiable {
    case settings
    case importLibrary
    case receivedRecipes(URL)

    var id: String {
        switch self {
        case .settings: return "settings"
        case .importLibrary: return "importLibrary"
        case .receivedRecipes(let url): return "receivedRecipes-\(url.absoluteString)"
        }
    }
}
