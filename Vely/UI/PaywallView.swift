import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseManager.self) var purchaseManager
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
                FeatureRow(icon: "rectangle.3.group", title: "paywall_feature_widget_title", description: "paywall_feature_widget_desc")
                FeatureRow(icon: "arrow.trianglehead.branch", title: "paywall_feature_trips_title", description: "paywall_feature_trips_desc")
                FeatureRow(icon: "star.fill", title: "paywall_feature_stations_title", description: "paywall_feature_stations_desc")
                FeatureRow(icon: "arrow.clockwise", title: "paywall_feature_refresh_title", description: "paywall_feature_refresh_desc")
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
