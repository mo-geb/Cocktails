import Foundation

enum ReviewManager {
    private static let viewCountKey = "reviewManager.detailViewCount"
    private static let lastRequestedCountKey = "reviewManager.lastRequestedCount"

    private static let milestones = [10, 50, 100]

    /// Call when a cocktail detail view appears. Returns `true` when a review prompt should be shown.
    static func recordCocktailViewed() -> Bool {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: viewCountKey) + 1
        defaults.set(count, forKey: viewCountKey)

        let lastRequested = defaults.integer(forKey: lastRequestedCountKey)
        guard let next = milestones.first(where: { $0 > lastRequested }), count >= next else {
            return false
        }

        defaults.set(count, forKey: lastRequestedCountKey)
        return true
    }
}
