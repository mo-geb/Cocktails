import SwiftUI

/// A simple thread-safe memory cache for extracted image colors.
@MainActor
final class ColorCache {
    static let shared = ColorCache()
    private init() {}

    private var cache: [String: Color] = [:]

    func color(for key: String) -> Color? {
        cache[key]
    }

    func set(_ color: Color, for key: String) {
        cache[key] = color
    }
}
