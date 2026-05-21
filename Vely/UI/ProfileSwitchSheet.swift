import SwiftUI

struct ProfileSwitchSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss

    private var strategy: any ProfileStrategy {
        switch profile {
        case .cyclist:     return CyclistStrategy()
        case .bikesharing: return BikesharingStrategy()
        }
    }

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
                ForEach(Array(strategy.switchBenefits.enumerated()), id: \.element) { index, benefit in
                    SwitchBenefitRow(
                        icon: benefit.icon,
                        color: benefit.color,
                        titleKey: benefit.titleKey,
                        fromKey: benefit.fromKey(targeting: profile),
                        toKey: benefit.toKey(targeting: profile)
                    )
                    if index < strategy.switchBenefits.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
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

// MARK: - SwitchBenefit display mapping

private extension SwitchBenefit {
    var icon: String {
        switch self {
        case .widget:       return "rectangle.3.group"
        case .notifications: return "bell.badge.fill"
        case .liveActivity: return "timer"
        }
    }

    var color: Color {
        switch self {
        case .widget:       return .indigo
        case .notifications: return .orange
        case .liveActivity: return .purple
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .widget:       return "paywall_feature_widget_title"
        case .notifications: return "trip_section_notification"
        case .liveActivity: return "paywall_feature_liveactivity_title"
        }
    }

    func fromKey(targeting profile: UserProfile) -> LocalizedStringKey {
        switch (self, profile) {
        case (.widget,       .cyclist):     return "profile_content_widget_bs"
        case (.widget,       .bikesharing): return "profile_content_widget_cy"
        case (.notifications, .cyclist):    return "profile_content_notif_bs"
        case (.notifications, .bikesharing): return "profile_content_notif_cy"
        case (.liveActivity, .cyclist):     return "profile_content_live_bs"
        case (.liveActivity, .bikesharing): return "profile_content_live_cy"
        }
    }

    func toKey(targeting profile: UserProfile) -> LocalizedStringKey {
        switch (self, profile) {
        case (.widget,       .cyclist):     return "profile_content_widget_cy"
        case (.widget,       .bikesharing): return "profile_content_widget_bs"
        case (.notifications, .cyclist):    return "profile_content_notif_cy"
        case (.notifications, .bikesharing): return "profile_content_notif_bs"
        case (.liveActivity, .cyclist):     return "profile_content_live_cy"
        case (.liveActivity, .bikesharing): return "profile_content_live_bs"
        }
    }
}

// MARK: - Row

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
