import UIKit
import SwiftUI

enum DisplayImageSource {
    case custom(UIImage)
    case system(String)
    case placeholder
}

extension DisplayImageSource {
    func dominantColor(placeholderName: String, cacheKey: String? = nil) async -> Color? {
        // Determine a suitable cache key
        let effectiveKey: String? = switch self {
        case .custom:           cacheKey
        case .system(let name): name
        case .placeholder:      "placeholder-\(placeholderName)"
        }

        // Check cache first
        if let effectiveKey, let cached = await ColorCache.shared.color(for: effectiveKey) {
            return cached
        }

        let uiImage: UIImage? = switch self {
        case .custom(let img):  img
        case .system(let name): UIImage(named: name)
        case .placeholder:      UIImage(named: placeholderName)
        }

        guard let uiImage else { return nil }

        let extracted = await Task.detached(priority: .userInitiated) {
            uiImage.dominantColor().map { Color($0) }
        }.value

        // Store in cache
        if let extracted, let effectiveKey {
            await ColorCache.shared.set(extracted, for: effectiveKey)
        }

        return extracted
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
