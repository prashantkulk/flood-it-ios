import StoreKit

// MARK: - P12-T4 Remove Ads IAP using StoreKit 2

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    static let removeAdsProductID = "com.prashantkulk.floodit.removeads"

    @Published private(set) var removeAdsProduct: Product?
    @Published private(set) var purchaseState: PurchaseState = .notPurchased

    enum PurchaseState {
        case notPurchased
        case purchasing
        case purchased
        case failed(String)
    }

    private var transactionListener: Task<Void, Never>?

    private init() {
        // Check persisted ad-free status first
        if adManager.isAdFree {
            purchaseState = .purchased
        }
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.removeAdsProductID])
            removeAdsProduct = products.first
        } catch {
            // Products won't load in simulator without App Store Connect setup
        }
    }

    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else { return }
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                applyAdFree()
                await transaction.finish()
            case .userCancelled:
                purchaseState = .notPurchased
            case .pending:
                purchaseState = .notPurchased
            @unknown default:
                purchaseState = .notPurchased
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    /// Restore purchases by checking current entitlements.
    func restorePurchases() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.removeAdsProductID {
                applyAdFree()
                return true
            }
        }
        return false
    }

    private func applyAdFree() {
        adManager.isAdFree = true
        purchaseState = .purchased
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue,
                   transaction.productID == StoreManager.removeAdsProductID {
                    await MainActor.run {
                        self?.applyAdFree()
                    }
                    await transaction.finish()
                }
            }
        }
    }
}
