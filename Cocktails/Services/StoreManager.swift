import Foundation
import StoreKit

@MainActor
@Observable
final class StoreManager {

    /// Maximum number of cocktails a non-paying user may keep.
    static let freeCocktailLimit = 10

    private let productID = "com.mo.Cocktails.unlimited"

    private(set) var product: Product?
    private(set) var isUnlimited = false
    private(set) var isLoadingProduct = false
    var purchaseInFlight = false

    init() {
        Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            async let loaded: Void = loadProduct()
            async let refreshed: Void = refreshEntitlements()
            _ = await (loaded, refreshed)
        }
    }

    // MARK: - Loading

    func loadProduct() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        product = try? await Product.products(for: [productID]).first
    }

    func loadProductIfNeeded() async {
        guard product == nil, !isLoadingProduct else { return }
        await loadProduct()
    }

    private func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        if isUnlimited != owned { isUnlimited = owned }
    }

    // MARK: - Actions

    func purchase() async {
        guard let product, !purchaseInFlight else { return }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        guard let result = try? await product.purchase() else { return }

        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                if !isUnlimited { isUnlimited = true }
                await transaction.finish()
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Gating

    /// Whether `requestedCount` more cocktails fit within the free tier.
    func canImport(currentCount: Int, requestedCount: Int) -> Bool {
        isUnlimited || currentCount + requestedCount <= Self.freeCocktailLimit
    }

    func canAddMore(currentCount: Int) -> Bool {
        canImport(currentCount: currentCount, requestedCount: 1)
    }

    // MARK: - Private

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == productID, transaction.revocationDate == nil, !isUnlimited {
            isUnlimited = true
        }
        await transaction.finish()
    }
}
