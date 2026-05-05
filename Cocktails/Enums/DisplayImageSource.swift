import UIKit
import SwiftUI

enum DisplayImageSource {
    case custom(UIImage)
    case system(String)
    case placeholder
}

extension DisplayImageSource {
    func dominantColor(placeholderName: String) -> Color? {
        let uiImage: UIImage? = switch self {
        case .custom(let img):  img
        case .system(let name): UIImage(named: name)
        case .placeholder:      UIImage(named: placeholderName)
        }
        return uiImage?.dominantColor().map { Color($0) }
    }
}
