import Foundation
import Observation

struct FavoriteEntry: Codable, Identifiable {
    var id: String { stationId }
    let stationId: String
    let cityId: String
    let stationName: String
    let stationAddress: String
}

@Observable
class FavoritesStore {
    private(set) var entries: [String: FavoriteEntry] = [:]

    @ObservationIgnored private let entriesKey = "favorite_entries_v2"
    @ObservationIgnored private let legacyKey = "favorite_station_ids"

    init() {
        load()
    }

    func isFavorite(_ station: BikeStation) -> Bool {
        entries[station.id] != nil
    }

    @discardableResult
    func toggle(_ station: BikeStation) -> Bool {
        if entries[station.id] != nil {
            entries.removeValue(forKey: station.id)
            save()
            return false
        } else {
            entries[station.id] = FavoriteEntry(
                stationId: station.id,
                cityId: station.cityId,
                stationName: station.name,
                stationAddress: station.address
            )
            save()
            return true
        }
    }

    func remove(stationId: String) {
        entries.removeValue(forKey: stationId)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Array(entries.values)) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let array = try? JSONDecoder().decode([FavoriteEntry].self, from: data) {
            entries = Dictionary(uniqueKeysWithValues: array.map { ($0.stationId, $0) })
            return
        }
        // Migration depuis l'ancien format (juste des IDs)
        let legacyIds = UserDefaults.standard.array(forKey: legacyKey) as? [String] ?? []
        guard !legacyIds.isEmpty else { return }
        entries = Dictionary(uniqueKeysWithValues: legacyIds.map { id in
            (id, FavoriteEntry(stationId: id, cityId: "", stationName: "", stationAddress: ""))
        })
        save()
    }
}
