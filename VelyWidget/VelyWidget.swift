import WidgetKit
import SwiftUI

// MARK: - Data

struct StationSnapshot {
    let stationId: String
    let name: String
    let cityName: String
    let bikesAvailable: Int
    let docksAvailable: Int
    let isOperational: Bool
    let isCached: Bool
}

struct VelyWidgetEntry: TimelineEntry {
    let date: Date
    let profile: UserProfile
    let slot1: StationSnapshot?
    let slot2: StationSnapshot?
    let addresses: [SavedAddress]
    let weatherSymbol: String?
    let weatherTemp: String?
    var isPremium: Bool = true
}

// MARK: - Provider

struct VelyWidgetProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.com.insightiq.Vely")
    private let repository = StationRepository()

    func placeholder(in context: Context) -> VelyWidgetEntry {
        VelyWidgetEntry(
            date: .now,
            profile: loadProfile(),
            slot1: .placeholder(slot: 1),
            slot2: .placeholder(slot: 2),
            addresses: [
                SavedAddress(name: "Maison", address: "12 rue de la Paix", latitude: 0, longitude: 0),
                SavedAddress(name: "Bureau", address: "45 av. de la République", latitude: 0, longitude: 0)
            ],
            weatherSymbol: "sun.max.fill",
            weatherTemp: "22°C"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VelyWidgetEntry) -> Void) {
        Task { completion(await buildEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VelyWidgetEntry>) -> Void) {
        Task {
            let entry = await buildEntry()
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date)!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func buildEntry() async -> VelyWidgetEntry {
        let profile = loadProfile()
        guard defaults?.bool(forKey: "is_premium") == true else {
            return VelyWidgetEntry(date: .now, profile: profile, slot1: nil, slot2: nil, addresses: [], weatherSymbol: nil, weatherTemp: nil, isPremium: false)
        }

        switch profile {
        case .cyclist:
            let addresses = loadAddresses()
            let symbol = defaults?.string(forKey: "cached_weather_symbol")
            let temp = defaults?.string(forKey: "cached_weather_temp")
            return VelyWidgetEntry(date: .now, profile: profile, slot1: nil, slot2: nil, addresses: addresses, weatherSymbol: symbol, weatherTemp: temp)

        case .bikesharing:
            let slotIds = loadSlotIds()
            let entries = loadFavoriteEntries()
            async let snap1 = fetchSnapshot(stationId: slotIds[0], entries: entries)
            async let snap2 = fetchSnapshot(stationId: slotIds[1], entries: entries)
            return VelyWidgetEntry(date: .now, profile: profile, slot1: await snap1, slot2: await snap2, addresses: [], weatherSymbol: nil, weatherTemp: nil)
        }
    }

    private func loadProfile() -> UserProfile {
        guard let raw = defaults?.string(forKey: "user_profile"),
              let p = UserProfile(rawValue: raw) else { return .bikesharing }
        return p
    }

    private func loadAddresses() -> [SavedAddress] {
        guard let data = defaults?.data(forKey: "saved_addresses"),
              let addresses = try? JSONDecoder().decode([SavedAddress].self, from: data)
        else { return [] }
        return Array(addresses.sorted { $0.name < $1.name }.prefix(2))
    }

    private func fetchSnapshot(stationId: String?, entries: [String: FavoriteEntry]) async -> StationSnapshot? {
        guard let id = stationId, let entry = entries[id] else { return nil }
        let city = City.staticAll.first { $0.id == entry.cityId }

        if let city {
            if let station = try? await repository.fetch(city: city).first(where: { $0.id == id }) {
                return StationSnapshot(
                    stationId: id,
                    name: station.name,
                    cityName: city.name,
                    bikesAvailable: station.bikesAvailable,
                    docksAvailable: station.docksAvailable,
                    isOperational: station.isOperational,
                    isCached: false
                )
            }
        }

        return StationSnapshot(
            stationId: id,
            name: entry.stationName.isEmpty ? id : entry.stationName,
            cityName: city?.name ?? entry.cityId,
            bikesAvailable: 0,
            docksAvailable: 0,
            isOperational: false,
            isCached: true
        )
    }

    private func loadSlotIds() -> [String?] {
        guard let data = defaults?.data(forKey: "widget_slot_ids"),
              let slots = try? JSONDecoder().decode([String].self, from: data)
        else { return [nil, nil] }
        return [
            slots.count > 0 && !slots[0].isEmpty ? slots[0] : nil,
            slots.count > 1 && !slots[1].isEmpty ? slots[1] : nil
        ]
    }

    private func loadFavoriteEntries() -> [String: FavoriteEntry] {
        guard let data = defaults?.data(forKey: "favorite_entries_v2"),
              let array = try? JSONDecoder().decode([FavoriteEntry].self, from: data)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: array.map { ($0.stationId, $0) })
    }
}

extension StationSnapshot {
    static func placeholder(slot: Int) -> StationSnapshot {
        StationSnapshot(
            stationId: "",
            name: slot == 1 ? "République" : "Grand Place",
            cityName: "Lille",
            bikesAvailable: slot == 1 ? 12 : 3,
            docksAvailable: slot == 1 ? 4 : 11,
            isOperational: true,
            isCached: false
        )
    }

    var statusColor: Color {
        guard isOperational else { return .red }
        return bikesAvailable > 0 ? .green : .orange
    }
}

// MARK: - Adaptive Theme

private struct WidgetBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.18),
                    Color(red: 0.03, green: 0.03, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 1.0),
                    Color(red: 0.89, green: 0.91, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Widget

struct VelyWidget: Widget {
    let kind = "VelyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VelyWidgetProvider()) { entry in
            VelyWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Vely")
        .description("Suivez vos favoris en temps réel.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View

struct VelyWidgetEntryView: View {
    let entry: VelyWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if !entry.isPremium {
            WidgetUpsellView()
        } else if entry.profile == .cyclist {
            switch family {
            case .systemMedium:
                CyclistMediumWidgetView(entry: entry)
            default:
                CyclistSmallWidgetView(entry: entry)
            }
        } else {
            switch family {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(station: entry.slot1 ?? entry.slot2)
            }
        }
    }
}

// MARK: - Small Widget (bikesharing)

struct SmallWidgetView: View {
    let station: StationSnapshot?
    @Environment(\.colorScheme) var colorScheme

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.08, green: 0.08, blue: 0.22) }
    private var secondaryText: Color { primaryText.opacity(0.45) }

    var body: some View {
        if let station {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Text(station.cityName.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(secondaryText)
                    Spacer()
                    Image(systemName: "bicycle.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.accentColor)
                }

                Spacer()

                // Station name
                Text(station.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 10)

                // Hero
                HStack(alignment: .bottom, spacing: 0) {
                    Text("\(station.bikesAvailable)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(primaryText)
                    VStack(alignment: .leading, spacing: 1) {
                        Image(systemName: "bicycle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                        Text("vélos")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.leading, 5)
                    .padding(.bottom, 5)
                }

                Spacer(minLength: 8)

                // Footer
                HStack(spacing: 5) {
                    Circle()
                        .fill(station.statusColor)
                        .frame(width: 6, height: 6)
                    Text("\(station.docksAvailable) places libres")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(secondaryText)
                    Spacer()
                    if station.isCached {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 9))
                            .foregroundStyle(secondaryText.opacity(0.6))
                    }
                }
            }
            .padding(14)
        } else {
            NotConfiguredView()
        }
    }
}

// MARK: - Medium Widget (bikesharing)

struct MediumWidgetView: View {
    let entry: VelyWidgetEntry
    @Environment(\.colorScheme) var colorScheme

    var sameCityHeader: String? {
        guard let s1 = entry.slot1, let s2 = entry.slot2,
              s1.cityName == s2.cityName else { return nil }
        return s1.cityName
    }

    private var secondaryText: Color {
        (colorScheme == .dark ? Color.white : Color(red: 0.08, green: 0.08, blue: 0.22)).opacity(0.45)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                if let city = sameCityHeader {
                    Text(city.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(secondaryText)
                }
                Spacer()
                Image(systemName: "bicycle.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 10)

            // Stations
            HStack(spacing: 0) {
                StationColumnView(station: entry.slot1, showCity: sameCityHeader == nil)
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.07))
                    .frame(width: 1)
                    .padding(.vertical, 2)
                StationColumnView(station: entry.slot2, showCity: sameCityHeader == nil)
            }
        }
        .padding(14)
    }
}

struct StationColumnView: View {
    let station: StationSnapshot?
    let showCity: Bool
    @Environment(\.colorScheme) var colorScheme

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.08, green: 0.08, blue: 0.22) }
    private var secondaryText: Color { primaryText.opacity(0.45) }

    var body: some View {
        Group {
            if let station {
                VStack(alignment: .leading, spacing: 4) {
                    if showCity {
                        Text(station.cityName.uppercased())
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .foregroundStyle(secondaryText)
                    }

                    Text(station.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    HStack(alignment: .bottom, spacing: 0) {
                        Text("\(station.bikesAvailable)")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(primaryText)
                        VStack(alignment: .leading, spacing: 1) {
                            Image(systemName: "bicycle")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                            Text("vélos")
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(secondaryText)
                        }
                        .padding(.leading, 4)
                        .padding(.bottom, 4)
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(station.statusColor)
                            .frame(width: 5, height: 5)
                        Text("\(station.docksAvailable) places")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(secondaryText)
                        if station.isCached {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 8))
                                .foregroundStyle(secondaryText.opacity(0.6))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor.opacity(0.3))
                    Text("Configurer\ndans Vely")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.primary.opacity(0.3))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
    }
}

// MARK: - Small Widget (cyclist)

struct CyclistSmallWidgetView: View {
    let entry: VelyWidgetEntry
    @Environment(\.colorScheme) var colorScheme

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.08, green: 0.08, blue: 0.22) }
    private var secondaryText: Color { primaryText.opacity(0.45) }
    private var hasWeather: Bool { entry.weatherSymbol != nil && entry.weatherTemp != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("CYCLISTE")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
                Spacer()
                Image(systemName: "figure.outdoor.cycle")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.accentColor)
            }

            if entry.addresses.isEmpty && !hasWeather {
                Spacer()
                CyclistNotConfiguredContent()
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                Spacer()

                if let symbol = entry.weatherSymbol, let temp = entry.weatherTemp {
                    HStack(alignment: .bottom, spacing: 4) {
                        Image(systemName: symbol)
                            .font(.system(size: 22))
                            .symbolRenderingMode(.multicolor)
                        Text(temp)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(primaryText)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: hasWeather ? 8 : 12)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.addresses.prefix(2)) { address in
                        HStack(spacing: 6) {
                            Image(systemName: address.systemIcon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(address.tintColor)
                                .frame(width: 16)
                            Text(address.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(primaryText)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Medium Widget (cyclist)

struct CyclistMediumWidgetView: View {
    let entry: VelyWidgetEntry
    @Environment(\.colorScheme) var colorScheme

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.08, green: 0.08, blue: 0.22) }
    private var secondaryText: Color { primaryText.opacity(0.45) }
    private var dividerColor: Color { colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.07) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("CYCLISTE")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
                Spacer()
                if let symbol = entry.weatherSymbol, let temp = entry.weatherTemp {
                    HStack(spacing: 4) {
                        Image(systemName: symbol)
                            .font(.system(size: 11))
                            .symbolRenderingMode(.multicolor)
                        Text(temp)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(primaryText)
                    }
                }
                Image(systemName: "figure.outdoor.cycle")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.accentColor)
                    .padding(.leading, 6)
            }
            .padding(.bottom, 10)

            if entry.addresses.isEmpty {
                Spacer()
                CyclistNotConfiguredContent()
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                HStack(spacing: 0) {
                    // Addresses column
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(entry.addresses.prefix(2).enumerated()), id: \.offset) { index, address in
                            if index > 0 {
                                Rectangle()
                                    .fill(dividerColor)
                                    .frame(height: 1)
                                    .padding(.vertical, 8)
                            }
                            HStack(spacing: 10) {
                                Image(systemName: address.systemIcon)
                                    .font(.system(size: 15))
                                    .foregroundStyle(address.tintColor)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(address.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(primaryText)
                                        .lineLimit(1)
                                    Text(address.address)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(secondaryText)
                                        .lineLimit(1)
                                }
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Weather column
                    if let symbol = entry.weatherSymbol, let temp = entry.weatherTemp {
                        Rectangle()
                            .fill(dividerColor)
                            .frame(width: 1)
                            .padding(.vertical, 2)

                        VStack(spacing: 4) {
                            Spacer()
                            Image(systemName: symbol)
                                .font(.system(size: 30))
                                .symbolRenderingMode(.multicolor)
                            Text(temp)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(primaryText)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                            Spacer()
                        }
                        .frame(width: 72)
                    }
                }
            }
        }
        .padding(14)
    }
}

private struct CyclistNotConfiguredContent: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.outdoor.cycle")
                .font(.system(size: 26))
                .foregroundStyle(Color.accentColor.opacity(0.6))
            Text("Ajouter des adresses\ndans Vely")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.35))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Upsell (non premium)

struct WidgetUpsellView: View {
    @Environment(\.colorScheme) var colorScheme

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.08, green: 0.08, blue: 0.22) }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
            Text("Vely Premium")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(primaryText)
            Text("Ouvrir Vely\npour s'abonner")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(primaryText.opacity(0.45))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Not Configured

struct NotConfiguredView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bicycle.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.accentColor.opacity(0.6))
            Text("Configurer\ndans Vely")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.35))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Previews

#Preview("Small – Bikesharing", as: .systemSmall) {
    VelyWidget()
} timeline: {
    VelyWidgetEntry(date: .now, profile: .bikesharing, slot1: .placeholder(slot: 1), slot2: .placeholder(slot: 2), addresses: [], weatherSymbol: nil, weatherTemp: nil)
    VelyWidgetEntry(date: .now, profile: .bikesharing, slot1: nil, slot2: nil, addresses: [], weatherSymbol: nil, weatherTemp: nil)
}

#Preview("Medium – Bikesharing", as: .systemMedium) {
    VelyWidget()
} timeline: {
    VelyWidgetEntry(date: .now, profile: .bikesharing, slot1: .placeholder(slot: 1), slot2: .placeholder(slot: 2), addresses: [], weatherSymbol: nil, weatherTemp: nil)
}

#Preview("Small – Cyclist", as: .systemSmall) {
    VelyWidget()
} timeline: {
    VelyWidgetEntry(
        date: .now, profile: .cyclist, slot1: nil, slot2: nil,
        addresses: [
            SavedAddress(name: "Maison", address: "12 rue de la Paix", latitude: 0, longitude: 0),
            SavedAddress(name: "Bureau", address: "45 av. de la République", latitude: 0, longitude: 0)
        ],
        weatherSymbol: "sun.max.fill", weatherTemp: "22°C"
    )
    VelyWidgetEntry(
        date: .now, profile: .cyclist, slot1: nil, slot2: nil,
        addresses: [],
        weatherSymbol: nil, weatherTemp: nil
    )
}

#Preview("Medium – Cyclist", as: .systemMedium) {
    VelyWidget()
} timeline: {
    VelyWidgetEntry(
        date: .now, profile: .cyclist, slot1: nil, slot2: nil,
        addresses: [
            SavedAddress(name: "Maison", address: "12 rue de la Paix", latitude: 0, longitude: 0),
            SavedAddress(name: "Bureau", address: "45 av. de la République", latitude: 0, longitude: 0)
        ],
        weatherSymbol: "cloud.sun.fill", weatherTemp: "18°C"
    )
    VelyWidgetEntry(
        date: .now, profile: .cyclist, slot1: nil, slot2: nil,
        addresses: [
            SavedAddress(name: "Maison", address: "12 rue de la Paix", latitude: 0, longitude: 0)
        ],
        weatherSymbol: nil, weatherTemp: nil
    )
}
