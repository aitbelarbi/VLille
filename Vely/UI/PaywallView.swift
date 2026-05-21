import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseManager.self) var purchaseManager
    @Environment(ProfileStore.self) var profileStore
    @Environment(\.dismiss) var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var product: Product? { purchaseManager.availableProducts.first }

    var priceLabel: String {
        guard let product else { return "2,99 €/mois" }
        return "\(product.displayPrice)/\(String(localized: "paywall_month"))"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.accentColor.gradient)
                        .frame(width: 80, height: 80)
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                .padding(.top, 32)

                Text("paywall_title")
                    .font(.title2.bold())

                Text("paywall_subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(profileStore.strategy.paywallFeatures, id: \.self) { feature in
                    FeatureRow(icon: feature.icon, title: feature.titleKey, description: feature.descriptionKey)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)

            Spacer()

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button {
                    Task { await buy() }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text("paywall_subscribe \(priceLabel)")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isPurchasing)

                Button {
                    Task { await purchaseManager.restorePurchases(); dismiss() }
                } label: {
                    Text("paywall_restore")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("paywall_terms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func buy() async {
        isPurchasing = true
        errorMessage = nil
        do {
            try await purchaseManager.purchase()
            if purchaseManager.isPremium { dismiss() }
        } catch {
            errorMessage = String(localized: "paywall_error")
        }
        isPurchasing = false
    }
}

private extension PaywallFeature {
    var icon: String {
        switch self {
        case .widget:       return "rectangle.3.group"
        case .trips:        return "arrow.trianglehead.branch"
        case .liveActivity: return "bell.badge.fill"
        case .stations:     return "star.fill"
        case .refresh:      return "arrow.clockwise"
        case .addresses:    return "mappin.circle.fill"
        }
    }
    var titleKey: LocalizedStringKey {
        switch self {
        case .widget:       return "paywall_feature_widget_title"
        case .trips:        return "paywall_feature_trips_title"
        case .liveActivity: return "paywall_feature_liveactivity_title"
        case .stations:     return "paywall_feature_stations_title"
        case .refresh:      return "paywall_feature_refresh_title"
        case .addresses:    return "paywall_feature_addresses_title"
        }
    }
    var descriptionKey: LocalizedStringKey {
        switch self {
        case .widget:       return "paywall_feature_widget_desc"
        case .trips:        return "paywall_feature_trips_desc"
        case .liveActivity: return "paywall_feature_liveactivity_desc"
        case .stations:     return "paywall_feature_stations_desc"
        case .refresh:      return "paywall_feature_refresh_desc"
        case .addresses:    return "paywall_feature_addresses_desc"
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
