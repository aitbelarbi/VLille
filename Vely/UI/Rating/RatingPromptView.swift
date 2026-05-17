import SwiftUI
import StoreKit
import MessageUI

struct RatingPromptView: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @Environment(RatingManager.self) private var ratingManager

    @State private var showMailComposer = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "star.bubble.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.indigo)
            }

            VStack(spacing: 8) {
                Text("rating_title")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("rating_subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    ratingManager.userSatisfied()
                    requestReview()
                } label: {
                    Text("rating_cta_positive")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.indigo)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    ratingManager.userWantsToGiveFeedback()
                    sendFeedback()
                } label: {
                    Text("rating_cta_negative")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.secondary.opacity(0.12))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(28)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                recipient: "contact@velyapp.com",
                subject: "[Retour Utilisateur] Suggestions pour Vely",
                onDismiss: { showMailComposer = false }
            )
            .ignoresSafeArea()
        }
    }

    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fallback : ouvre l'app Mail ou un client tiers
            var components = URLComponents()
            components.scheme = "mailto"
            components.path = "contact@velyapp.com"
            components.queryItems = [
                URLQueryItem(name: "subject", value: "[Retour Utilisateur] Suggestions pour Vely")
            ]
            if let url = components.url { openURL(url) }
        }
    }
}
