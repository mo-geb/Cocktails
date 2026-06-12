import Foundation
import StoreKit

@MainActor
@Observable
final class StoreManager {

    /// Maximum number of cocktails a non-paying user may keep.
    static let freeCocktailLimit = 10

    static let unlimitedProductID = "com.mo.Cocktails.unlimited"

    private(set) var isUnlimited = false
    private(set) var restoreInFlight = false

    /// Mirrors the App Store entitlement; kept current by the
    /// `currentEntitlementTask` attached at the app root.
    func updateEntitlement(from result: VerificationResult<Transaction>?) {
        guard case .verified(let transaction) = result else {
            isUnlimited = false
            return
        }
        isUnlimited = transaction.revocationDate == nil
    }

    func restore() async {
        guard !restoreInFlight else { return }
        restoreInFlight = true
        defer { restoreInFlight = false }

        try? await AppStore.sync()
        var latest: VerificationResult<Transaction>?
        for await result in Transaction.currentEntitlements(for: Self.unlimitedProductID) {
            latest = result
        }
        updateEntitlement(from: latest)
    }

    // MARK: - Gating

    /// Whether `requestedCount` more cocktails fit within the free tier.
    func canImport(currentCount: Int, requestedCount: Int) -> Bool {
        isUnlimited || currentCount + requestedCount <= Self.freeCocktailLimit
    }

    func canAddMore(currentCount: Int) -> Bool {
        canImport(currentCount: currentCount, requestedCount: 1)
    }
}
