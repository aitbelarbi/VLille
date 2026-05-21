import SwiftUI

struct ProfileSwitchSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss

    private var icon: String {
        profile == .cyclist ? "figure.outdoor.cycle" : "bicycle.circle.fill"
    }

    private var titleKey: LocalizedStringKey {
        profile == .cyclist ? "profile_cyclist_title" : "profile_bikesharing_title"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundStyle(.indigo)
                }
                .padding(.top, 32)

                Text(titleKey)
                    .font(.title2.bold())

                Text("profile_switch_subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [Color.indigo.opacity(0.08), Color.clear], startPoint: .top, endPoint: .bottom)
            )

            VStack(alignment: .leading, spacing: 0) {
                SwitchBenefitRow(
                    icon: "rectangle.3.group",
                    color: .indigo,
                    titleKey: "paywall_feature_widget_title",
                    fromKey: profile == .cyclist ? "profile_content_widget_bs" : "profile_content_widget_cy",
                    toKey:   profile == .cyclist ? "profile_content_widget_cy" : "profile_content_widget_bs"
                )
                Divider().padding(.leading, 56)
                SwitchBenefitRow(
                    icon: "bell.badge.fill",
                    color: .orange,
                    titleKey: "trip_section_notification",
                    fromKey: profile == .cyclist ? "profile_content_notif_bs" : "profile_content_notif_cy",
                    toKey:   profile == .cyclist ? "profile_content_notif_cy" : "profile_content_notif_bs"
                )
                Divider().padding(.leading, 56)
                SwitchBenefitRow(
                    icon: "timer",
                    color: .purple,
                    titleKey: "paywall_feature_liveactivity_title",
                    fromKey: profile == .cyclist ? "profile_content_live_bs" : "profile_content_live_cy",
                    toKey:   profile == .cyclist ? "profile_content_live_cy" : "profile_content_live_bs"
                )
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()

            Button { dismiss() } label: {
                Text("profile_switch_cta")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.indigo, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .shadow(color: .indigo.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct SwitchBenefitRow: View {
    let icon: String
    let color: Color
    let titleKey: LocalizedStringKey
    let fromKey: LocalizedStringKey
    let toKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(titleKey)
                    .font(.subheadline.bold())
                HStack(spacing: 5) {
                    Text(fromKey)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                    Text(toKey)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    ProfileSwitchSheet(profile: .cyclist)
}

#Preview("Bikesharing") {
    ProfileSwitchSheet(profile: .bikesharing)
}
