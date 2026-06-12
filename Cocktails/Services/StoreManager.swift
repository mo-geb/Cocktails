import Foundation
import StoreKit

@MainActor
@Observable
final class StoreManager {

    /// Maximum number of cocktails a non-paying user may keep.
    static let freeCocktailLimit = 10

    static let unlimitedProductID = "com.mo.Cocktails.unlimited"

    private(set) var isUnlimited = UserDefaults.standard.bool(forKey: "isUnlimited") {
        didSet { UserDefaults.standard.set(isUnlimited, forKey: "isUnlimited") }
    }
    private(set) var restoreInFlight = false

    init() {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self?.process(transaction)
            }
        }
    }

    private func process(_ transaction: Transaction) async {
        if transaction.productID == Self.unlimitedProductID {
            isUnlimited = transaction.revocationDate == nil
        }
        await transaction.finish()
    }

    func updateEntitlement(from result: VerificationResult<Transaction>?) async {
        guard case .verified(let transaction) = result else { return }
        await process(transaction)
    }

    func handlePurchaseResult(_ result: Result<Product.PurchaseResult, any Error>) async {
        guard case .success(.success(let verification)) = result,
              case .verified(let transaction) = verification else { return }
        await process(transaction)
    }

    func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            await process(transaction)
        }
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
        await updateEntitlement(from: latest)
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
