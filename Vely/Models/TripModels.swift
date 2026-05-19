import Foundation

// MARK: - TripWaypoint resolution

extension TripWaypoint {
    /// Resolve to the concrete favorite item, optionally enriched with live station data.
    func resolve(in favoritesStore: FavoritesStore, liveStations: [BikeStation] = []) -> (any FavoriteItem)? {
        switch self {
        case .stationFavorite(let stationId):
            guard let entry = favoritesStore.entries[stationId] else { return nil }
            let live = liveStations.first { $0.id == stationId }
            return StationFavorite(entry: entry, liveStation: live, slot: nil)
        case .addressFavorite(let addressId):
            guard let address = favoritesStore.savedAddresses.first(where: { $0.id == addressId }) else { return nil }
            return AddressFavorite(address: address)
        }
    }
}

extension TripWaypoint {
    static func from(_ item: StationFavorite) -> TripWaypoint { .stationFavorite(stationId: item.entry.stationId) }
    static func from(_ item: AddressFavorite) -> TripWaypoint { .addressFavorite(addressId: item.address.id) }
}

// MARK: - Models

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7, sunday = 1

    var id: Int { rawValue }

    var shortName: String {
        Calendar.current.shortWeekdaySymbols[rawValue == 1 ? 0 : rawValue - 1]
    }
}

struct TripSchedule: Codable {
    var days: Set<Weekday>
    var departureHour: Int
    var departureMinute: Int
}

enum TripWaypoint: Codable {
    case stationFavorite(stationId: String)
    case addressFavorite(addressId: UUID)
}

struct Trip: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var profile: UserProfile
    var schedule: TripSchedule
    var origin: TripWaypoint
    var destination: TripWaypoint
}
