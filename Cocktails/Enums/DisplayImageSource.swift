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
