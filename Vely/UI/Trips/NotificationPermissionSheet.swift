import SwiftUI
import UIKit

struct NotificationPermissionSheet: View {
    let notificationManager: NotificationManager
    let tripName: String
    let leadMinutes: Int
    let onGranted: () -> Void
    let onDismissed: () -> Void

    @State private var isRequesting = false

    private var isDenied: Bool { notificationManager.authorizationStatus == .denied }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                notificationPreview
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                benefitRows
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer()

                ctaArea
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.10))
                    .frame(width: 80, height: 80)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.indigo)
            }
            .padding(.top, 28)

            Text("notif_permission_title")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("notif_permission_subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color.indigo.opacity(0.08), Color.clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Notification preview card

    private var notificationPreview: some View {
        let title = tripName.isEmpty
            ? NSLocalizedString("trip_notification_title", comment: "")
            : tripName
        let body = String(
            format: NSLocalizedString("trip_notification_body", comment: ""),
            leadMinutes
        )

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.indigo)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "bicycle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Vely")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("notif_preview_now")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    // MARK: - Benefit rows

    private var benefitRows: some View {
        VStack(spacing: 0) {
            NotifBenefitRow(icon: "alarm.fill", color: .indigo, key: "notif_benefit_reminder")
            Divider().padding(.leading, 56)
            NotifBenefitRow(icon: "slider.horizontal.3", color: .orange, key: "notif_benefit_timing")
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - CTA

    private var ctaArea: some View {
        VStack(spacing: 12) {
            Button {
                if isDenied {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } else {
                    requestPermission()
                }
            } label: {
                HStack(spacing: 10) {
                    if isRequesting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: isDenied ? "gear" : "bell.fill")
                    }
                    Text(isDenied
                         ? LocalizedStringKey("location_denied_open_settings")
                         : LocalizedStringKey("notif_permission_enable"))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.indigo, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .shadow(color: .indigo.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isRequesting)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.clear, Color(.systemGroupedBackground).opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Logic

    private func requestPermission() {
        isRequesting = true
        Task {
            let granted = await notificationManager.requestAuthorization()
            await MainActor.run {
                isRequesting = false
                if granted { onGranted() } else { onDismissed() }
            }
        }
    }
}

// MARK: - NotifBenefitRow

private struct NotifBenefitRow: View {
    let icon: String
    let color: Color
    let key: LocalizedStringKey

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
            Text(key)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
