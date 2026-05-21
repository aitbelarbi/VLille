import SwiftUI
import WeatherKit

struct TripCardView: View {
    let trip: Trip
    let originItem: (any FavoriteItem)?
    let destinationItem: (any FavoriteItem)?
    let weather: CurrentWeather?
    let isWeatherProfile: Bool
    let onEdit: () -> Void

    private enum LiveStatus {
        case bikes(available: Int, docks: Int, operational: Bool)
        case weather(symbolName: String, temp: String, isHarsh: Bool, isModerate: Bool)
        case unavailable

        var color: Color {
            switch self {
            case .bikes(let available, _, let operational):
                guard operational else { return .red }
                if available == 0 { return .red }
                return available <= 2 ? .orange : .green
            case .weather(_, _, let isHarsh, let isModerate):
                if isHarsh { return .red }
                return isModerate ? .orange : .green
            case .unavailable:
                return Color.secondary.opacity(0.4)
            }
        }
    }

    private var liveStatus: LiveStatus {
        if isWeatherProfile {
            guard let w = weather else { return .unavailable }
            let tempStr = w.temperature.formatted(
                .measurement(width: .narrow, numberFormatStyle: .number.precision(.fractionLength(0)))
            )
            let windKmh = w.wind.speed.converted(to: .kilometersPerHour).value
            let precipMmh = w.precipitationIntensity.value
            return .weather(
                symbolName: w.symbolName,
                temp: tempStr,
                isHarsh: windKmh > 50 || precipMmh > 3,
                isModerate: windKmh > 25 || precipMmh > 0.5
            )
        } else {
            guard let bikes = originItem?.bikesAvailable,
                  let docks = originItem?.docksAvailable else { return .unavailable }
            return .bikes(available: bikes, docks: docks, operational: originItem?.isActive ?? false)
        }
    }

    private var tripDisplayName: String {
        if !trip.name.isEmpty { return trip.name }
        let o = originItem?.displayName ?? "?"
        let d = destinationItem?.displayName ?? "?"
        return "\(o) → \(d)"
    }

    private let displayOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(liveStatus.color)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 10) {
                    nameAndTimeRow
                    dayPillsRow
                    routeView
                    statusRow
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(liveStatus.color.opacity(0.2), lineWidth: 1))
    }

    private var nameAndTimeRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(tripDisplayName)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Text(String(format: "%02d:%02d", trip.schedule.departureHour, trip.schedule.departureMinute))
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(.secondary)
        }
    }

    private var dayPillsRow: some View {
        HStack(spacing: 4) {
            ForEach(displayOrder) { day in
                let active = trip.schedule.days.contains(day)
                Text(String(day.shortName.prefix(2)).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 28, height: 22)
                    .background(
                        active ? Color.indigo : Color.secondary.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .foregroundStyle(active ? .white : .secondary)
            }
            Spacer()
        }
    }

    private var routeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            waypointRow(item: originItem, isOrigin: true)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 10)
                    .padding(.leading, 11)
                Spacer()
            }
            waypointRow(item: destinationItem, isOrigin: false)
        }
    }

    private func waypointRow(item: (any FavoriteItem)?, isOrigin: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item?.rowLeadingIcon ?? (isOrigin ? "mappin.circle.fill" : "flag.fill"))
                .font(.system(size: 14))
                .foregroundStyle(item?.rowLeadingColor ?? .secondary)
                .frame(width: 22, alignment: .center)
            Text(item?.displayName ?? String(localized: isOrigin ? "trip_origin_placeholder" : "trip_destination_placeholder"))
                .font(.subheadline)
                .foregroundStyle(item != nil ? .primary : .secondary)
                .lineLimit(1)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(liveStatus.color)
                .frame(width: 7, height: 7)
            if case .weather(let symbolName, let temp, _, _) = liveStatus {
                Label(temp, systemImage: symbolName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if case .unavailable = liveStatus {
                Text("trip_status_unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
