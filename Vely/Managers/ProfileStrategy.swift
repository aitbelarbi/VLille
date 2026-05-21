import Foundation

// MARK: - UserProfile

enum UserProfile: String, Codable, Identifiable {
    case bikesharing
    case cyclist
    var id: String { rawValue }
}

// MARK: - FavoriteSection

struct FavoriteSection: Identifiable {
    let id: String
    let title: String
    let items: [any FavoriteItem]
    let cityId: String?
}

// MARK: - Strategy enums

enum WidgetDataKind {
    case stations
    case addresses
}

enum LiveActivityStatusSource {
    case bikeCount
    case weather
}

enum PaywallFeature: Hashable {
    case widget
    case trips
    case liveActivity
    case stations
    case refresh
    case addresses
}

enum SwitchBenefit: Hashable {
    case widget
    case notifications
    case liveActivity
}

struct EmptyStateConfig {
    let titleKey: String
    let hintKey: String
    let icon: String
}

extension UserProfile {
    var widgetDataKind: WidgetDataKind {
        switch self {
        case .bikesharing: return .stations
        case .cyclist:     return .addresses
        }
    }
}

// MARK: - Protocol

protocol ProfileStrategy {
    var profile: UserProfile { get }
    var shouldLoadStations: Bool { get }
    var searchIncludesStations: Bool { get }
    var supportsWidgets: Bool { get }
    var canAddAddressFavorites: Bool { get }
    var widgetDataKind: WidgetDataKind { get }
    var liveActivityStatusSource: LiveActivityStatusSource { get }
    var notificationIncludesWeather: Bool { get }
    var paywallFeatures: [PaywallFeature] { get }
    var switchBenefits: [SwitchBenefit] { get }
    var emptyFavoritesConfig: EmptyStateConfig { get }

    func hasFavorites(in stores: FavoriteStores) -> Bool

    func favoriteSections(
        stores: FavoriteStores,
        liveStations: [BikeStation],
        currentCity: City,
        cities: [City],
        isPremium: Bool
    ) -> [FavoriteSection]

    func mapAnnotations(from addressStore: AddressStore) -> [AddressFavorite]

    func tripWaypointCandidates(stores: FavoriteStores, currentCity: City) -> [any FavoriteItem]
}

// MARK: - BikesharingStrategy

struct BikesharingStrategy: ProfileStrategy {
    var profile: UserProfile { .bikesharing }
    var shouldLoadStations: Bool { true }
    var searchIncludesStations: Bool { true }
    var supportsWidgets: Bool { true }
    var canAddAddressFavorites: Bool { false }
    var widgetDataKind: WidgetDataKind { .stations }
    var liveActivityStatusSource: LiveActivityStatusSource { .bikeCount }
    var notificationIncludesWeather: Bool { false }
    var paywallFeatures: [PaywallFeature] { [.widget, .trips, .liveActivity, .stations, .refresh] }
    var switchBenefits: [SwitchBenefit] { [.widget, .notifications, .liveActivity] }
    var emptyFavoritesConfig: EmptyStateConfig { EmptyStateConfig(titleKey: "favorites_empty_title", hintKey: "favorites_empty_hint", icon: "star.slash") }

    func hasFavorites(in stores: FavoriteStores) -> Bool {
        !stores.favorites.entries.isEmpty
    }

    func favoriteSections(
        stores: FavoriteStores,
        liveStations: [BikeStation],
        currentCity: City,
        cities: [City],
        isPremium: Bool
    ) -> [FavoriteSection] {
        let store = stores.favorites
        let activeIds = Set(liveStations.map { $0.id })

        let activeFavorites: [any FavoriteItem] = liveStations
            .filter { store.isFavorite($0) }
            .sorted { $0.name < $1.name }
            .map { station in
                StationFavorite(
                    entry: store.entries[station.id]!,
                    liveStation: station,
                    slot: isPremium ? store.widgetSlot(for: station.id, cityId: currentCity.id) : nil
                )
            }

        let grouped = Dictionary(
            grouping: store.entries.values.filter {
                !activeIds.contains($0.stationId) &&
                $0.cityId != currentCity.id &&
                !$0.cityId.isEmpty
            },
            by: \.cityId
        )
        let inactiveSections: [FavoriteSection] = grouped.map { cityId, entries in
            let cityName = cities.first { $0.id == cityId }?.name ?? cityId
            let items: [any FavoriteItem] = entries
                .sorted { $0.stationName < $1.stationName }
                .map { StationFavorite(entry: $0, liveStation: nil, slot: nil) }
            return FavoriteSection(id: "city_\(cityId)", title: cityName, items: items, cityId: cityId)
        }.sorted { $0.title < $1.title }

        var sections: [FavoriteSection] = []
        if !activeFavorites.isEmpty {
            sections.append(FavoriteSection(
                id: "active_\(currentCity.id)",
                title: currentCity.name,
                items: activeFavorites,
                cityId: currentCity.id
            ))
        }
        sections.append(contentsOf: inactiveSections)
        return sections
    }

    func mapAnnotations(from addressStore: AddressStore) -> [AddressFavorite] { [] }

    func tripWaypointCandidates(stores: FavoriteStores, currentCity: City) -> [any FavoriteItem] {
        stores.favorites.entries.values
            .filter { $0.cityId == currentCity.id }
            .sorted { $0.stationName < $1.stationName }
            .map { StationFavorite(entry: $0, liveStation: nil, slot: nil) }
    }
}

// MARK: - CyclistStrategy

struct CyclistStrategy: ProfileStrategy {
    var profile: UserProfile { .cyclist }
    var shouldLoadStations: Bool { false }
    var searchIncludesStations: Bool { false }
    var supportsWidgets: Bool { true }
    var canAddAddressFavorites: Bool { true }
    var widgetDataKind: WidgetDataKind { .addresses }
    var liveActivityStatusSource: LiveActivityStatusSource { .weather }
    var notificationIncludesWeather: Bool { true }
    var paywallFeatures: [PaywallFeature] { [.widget, .trips, .liveActivity, .addresses] }
    var switchBenefits: [SwitchBenefit] { [.widget, .notifications, .liveActivity] }
    var emptyFavoritesConfig: EmptyStateConfig { EmptyStateConfig(titleKey: "cyclist_addresses_empty_title", hintKey: "cyclist_addresses_empty_hint", icon: "mappin.slash") }

    func hasFavorites(in stores: FavoriteStores) -> Bool {
        !stores.addresses.savedAddresses.isEmpty
    }

    func favoriteSections(
        stores: FavoriteStores,
        liveStations: [BikeStation],
        currentCity: City,
        cities: [City],
        isPremium: Bool
    ) -> [FavoriteSection] {
        let items: [any FavoriteItem] = stores.addresses.savedAddresses
            .filter { $0.cityId == currentCity.id }
            .sorted { $0.name < $1.name }
            .map { AddressFavorite(address: $0) }
        guard !items.isEmpty else { return [] }
        return [FavoriteSection(id: "addresses", title: "", items: items, cityId: currentCity.id)]
    }

    func mapAnnotations(from addressStore: AddressStore) -> [AddressFavorite] {
        addressStore.savedAddresses.map { AddressFavorite(address: $0) }
    }

    func tripWaypointCandidates(stores: FavoriteStores, currentCity: City) -> [any FavoriteItem] {
        stores.addresses.savedAddresses
            .filter { $0.cityId == currentCity.id || $0.cityId.isEmpty }
            .sorted { $0.name < $1.name }
            .map { AddressFavorite(address: $0) }
    }
}
