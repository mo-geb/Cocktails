import UIKit
import SwiftUI

enum DisplayImageSource {
    case custom(UIImage)
    case system(String)
    case placeholder
}

extension DisplayImageSource {
    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }

    func dominantColor(placeholderName: String) -> Color? {
        let uiImage: UIImage? = switch self {
        case .custom(let img):  img
        case .system(let name): UIImage(named: name)
        case .placeholder:      UIImage(named: placeholderName)
        }
        return uiImage?.dominantColor().map { Color($0) }
    }

    @ViewBuilder
    func view(placeholder: String) -> some View {
        switch self {
        case .custom(let uiImage): Image(uiImage: uiImage).resizable()
        case .system(let name):    Image(name).resizable()
        case .placeholder:         Image(placeholder).resizable()
        }
    }
}

// MARK: - Cocktail image providing

protocol CocktailImageProviding {
    var imageData: Data? { get }
    var imageName: String? { get }
}

extension CocktailImageProviding {
    var displayImage: DisplayImageSource {
        if let data = imageData, let uiImage = UIImage(data: data) {
            return .custom(uiImage)
        }
        if let name = imageName, UIImage(named: "Cocktail/" + name) != nil {
            return .system("Cocktail/" + name)
        }
        return .placeholder
    }
}

extension Cocktail: CocktailImageProviding {}
extension CocktailDraft: CocktailImageProviding {}
extension CocktailDTO: CocktailImageProviding {
    var imageData: Data? { nil }
}

// MARK: - Ingredient image providing

protocol IngredientImageProviding {
    var id: String { get }
    var imageName: String? { get }
}

extension IngredientImageProviding {
    var displayImage: DisplayImageSource {
        let assetName = "Ingredient/" + (imageName ?? id)
        if UIImage(named: assetName) != nil {
            return .system(assetName)
        }
        return .placeholder
    }
}

extension Ingredient: IngredientImageProviding {}
extension IngredientDraft: IngredientImageProviding {}
