import SwiftUI

struct UnsupportedCityBanner: View {
    let cityName: String

    private var mailtoURL: URL? {
        let subject = String(format: String(localized: "unsupported_city_mail_subject"), cityName)
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:contact@velyapp.com?subject=\(encoded)")
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.slash.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("unsupported_city_title")
                    .font(.subheadline.weight(.semibold))
                Text("unsupported_city_subtitle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let url = mailtoURL {
                Link(destination: url) {
                    Text("unsupported_city_cta")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.orange.opacity(0.15), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}
