import SwiftUI
import MessageUI

struct GhostCityPromptView: View {
    @Environment(\.openURL) private var openURL
    @Environment(GhostCityManager.self) private var ghostCityManager

    @State private var showMailComposer = false
    @State private var citySnapshot: City?

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 8) {
                Text("ghost_city_title")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(String(format: String(localized: "ghost_city_subtitle"), citySnapshot?.localizedName ?? ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    ghostCityManager.userContacted()
                    sendReport()
                } label: {
                    Text("ghost_city_contact")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    ghostCityManager.dismiss()
                } label: {
                    Text("ghost_city_dismiss")
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
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .onAppear { citySnapshot = ghostCityManager.pendingCity }
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                recipient: "contact@velyapp.com",
                subject: mailSubject,
                body: mailBody,
                onDismiss: { showMailComposer = false }
            )
            .ignoresSafeArea()
        }
    }

    private var mailSubject: String {
        "[Vely] Ville inactive : \(citySnapshot?.localizedName ?? "")"
    }

    private var mailBody: String {
        """
        Bonjour,

        La ville \(citySnapshot?.localizedName ?? "") (\(citySnapshot?.serviceName ?? "")) \
        ne semble plus retourner de stations.

        ID : \(citySnapshot?.id ?? "")
        """
    }

    private func sendReport() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            var components = URLComponents()
            components.scheme = "mailto"
            components.path = "contact@velyapp.com"
            components.queryItems = [
                URLQueryItem(name: "subject", value: mailSubject),
                URLQueryItem(name: "body",    value: mailBody)
            ]
            if let url = components.url { openURL(url) }
        }
    }
}
