import Foundation

// MARK: - UserProfile

enum UserProfile: String, Codable {
    case bikesharing
    case cyclist
}

// MARK: - FavoriteSection

struct FavoriteSection: Identifiable {
    let id: String
    let title: String
    let items: [any FavoriteItem]
    let cityId: String?
}

// MARK: - Protocol

protocol ProfileStrategy {
    var profile: UserProfile { get }
    var shouldLoadStations: Bool { get }
    var searchIncludesStations: Bool { get }
    var supportsWidgets: Bool { get }
    var canAddAddressFavorites: Bool { get }

    func hasFavorites(in store: FavoritesStore) -> Bool

    func favoriteSections(
        store: FavoritesStore,
        liveStations: [BikeStation],
        currentCity: City,
        cities: [City],
        isPremium: Bool
    ) -> [FavoriteSection]

    func mapAnnotations(from store: FavoritesStore) -> [AddressFavorite]

    /// All items selectable as trip waypoints for this profile, scoped to the current city.
    func tripWaypointCandidates(from store: FavoritesStore, currentCity: City) -> [any FavoriteItem]
}

// MARK: - BikesharingStrategy

struct BikesharingStrategy: ProfileStrategy {
    var profile: UserProfile { .bikesharing }
    var shouldLoadStations: Bool { true }
    var searchIncludesStations: Bool { true }
    var supportsWidgets: Bool { true }
    var canAddAddressFavorites: Bool { false }

    func hasFavorites(in store: FavoritesStore) -> Bool {
        !store.entries.isEmpty
    }

    func favoriteSections(
        store: FavoritesStore,
        liveStations: [BikeStation],
        currentCity: City,
        cities: [City],
        isPremium: Bool
    ) -> [FavoriteSection] {
        let activeIds = Set(liveStations.map { $0.id })

        let activeFavorites: [any FavoriteItem] = liveStations
            .filter { store.isFavorite($0) }
            .sorted { $0.name < $1.name }
            .map { station in
                StationFavorite(
                    entry: store.entries[station.id]!,
                    liveStation: station,
                    slot: isPremium ? store.widgetSlot(for: station.id) : nil
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

    func mapAnnotations(from store: FavoritesStore) -> [AddressFavorite] { [] }

    func tripWaypointCandidates(from store: FavoritesStore, currentCity: City) -> [any FavoriteItem] {
        store.entries.values
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
    var supportsWidgets: Bool { false }
    var canAddAddressFavorites: Bool { true }

    func hasFavorites(in store: FavoritesStore) -> Bool {
        !store.savedAddresses.isEmpty
    }

    func favoriteSections(
        store: FavoritesStore,
        liveStations: [BikeStation],
        currentCity: City,
        cities: [City],
        isPremium: Bool
    ) -> [FavoriteSection] {
        let items: [any FavoriteItem] = store.savedAddresses
            .sorted { $0.name < $1.name }
            .map { AddressFavorite(address: $0) }
        guard !items.isEmpty else { return [] }
        return [FavoriteSection(id: "addresses", title: "", items: items, cityId: nil)]
    }

    func mapAnnotations(from store: FavoritesStore) -> [AddressFavorite] {
        store.savedAddresses.map { AddressFavorite(address: $0) }
    }

    func tripWaypointCandidates(from store: FavoritesStore, currentCity: City) -> [any FavoriteItem] {
        store.savedAddresses
            .sorted { $0.name < $1.name }
            .map { AddressFavorite(address: $0) }
    }
}
