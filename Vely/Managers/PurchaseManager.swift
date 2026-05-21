import Foundation
import Observation
import StoreKit
import WidgetKit

@Observable
@MainActor
final class PurchaseManager {
    private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    private(set) var availableProducts: [Product] = []

    // À remplacer par le vrai product ID depuis App Store Connect
    static let premiumProductID = "com.insightiq.Vely.premium.monthly"

    var isPremium: Bool {
        #if DEBUG
        if debugPremiumOverride { return true }
        #endif
        switch subscriptionStatus {
        case .subscribed, .inGracePeriod: return true
        default: return false
        }
    }

    #if DEBUG
    var debugPremiumOverride = false
    #endif

    @ObservationIgnored private let persistence = PersistenceStore.shared
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForTransactionUpdates() }
    }

    func loadProducts() async {
        do {
            availableProducts = try await Product.products(for: [Self.premiumProductID])
        } catch {
            print("⚠️ [PurchaseManager] Failed to load products: \(error)")
        }
    }

    func purchase() async throws {
        guard let product = availableProducts.first else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    func updateSubscriptionStatus() async {
        guard let product = availableProducts.first,
              let statuses = try? await product.subscription?.status else {
            subscriptionStatus = .notSubscribed
            syncPremiumStatus()
            return
        }

        let active = statuses.first { status in
            switch status.state {
            case .subscribed, .inGracePeriod: return true
            default: return false
            }
        }

        guard let activeStatus = active,
              case .verified(let renewalInfo) = activeStatus.renewalInfo,
              case .verified(_) = activeStatus.transaction else {
            subscriptionStatus = .notSubscribed
            syncPremiumStatus()
            return
        }

        subscriptionStatus = renewalInfo.willAutoRenew ? .subscribed : .inGracePeriod
        syncPremiumStatus()
    }

    private func syncPremiumStatus() {
        persistence.set(.isPremium, isPremium)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await updateSubscriptionStatus()
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }
}

enum SubscriptionStatus {
    case unknown
    case subscribed
    case inGracePeriod
    case notSubscribed
}
