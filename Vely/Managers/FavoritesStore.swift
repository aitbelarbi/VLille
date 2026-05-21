import Foundation
import Observation
import WidgetKit

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
    private(set) var widgetSlotIdsByCity: [String: [String?]] = [:]

    @ObservationIgnored private let persistence = PersistenceStore.shared

    init() { load() }

    func isFavorite(_ station: BikeStation) -> Bool {
        entries[station.id] != nil
    }

    func widgetSlots(for cityId: String) -> [String?] {
        widgetSlotIdsByCity[cityId] ?? [nil, nil]
    }

    func widgetSlot(for stationId: String, cityId: String) -> Int? {
        let slots = widgetSlots(for: cityId)
        if slots[0] == stationId { return 1 }
        if slots[1] == stationId { return 2 }
        return nil
    }

    func setWidgetSlot(_ index: Int, stationId: String?, cityId: String) {
        guard index < 2 else { return }
        var slots = widgetSlots(for: cityId)
        let otherIndex = index == 0 ? 1 : 0
        if let id = stationId, slots[otherIndex] == id {
            slots[otherIndex] = nil
        }
        slots[index] = stationId
        widgetSlotIdsByCity[cityId] = slots
        saveWidgetSlots()
        WidgetCenter.shared.reloadAllTimelines()
    }

    @discardableResult
    func toggle(_ station: BikeStation) -> Bool {
        if entries[station.id] != nil {
            removeFromWidgetSlots(stationId: station.id)
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
        removeFromWidgetSlots(stationId: stationId)
        entries.removeValue(forKey: stationId)
        save()
    }

    func healEntries(with stations: [BikeStation]) {
        var changed = false
        for station in stations {
            if let entry = entries[station.id],
               entry.stationName.isEmpty || entry.cityId.isEmpty {
                entries[station.id] = FavoriteEntry(
                    stationId: station.id,
                    cityId: station.cityId,
                    stationName: station.name,
                    stationAddress: station.address
                )
                changed = true
            }
        }
        if changed { save() }
    }

    private func removeFromWidgetSlots(stationId: String) {
        var changed = false
        for cityId in widgetSlotIdsByCity.keys {
            var slots = widgetSlotIdsByCity[cityId]!
            for i in 0..<2 where slots[i] == stationId {
                slots[i] = nil
                changed = true
            }
            if changed { widgetSlotIdsByCity[cityId] = slots }
        }
        if changed { saveWidgetSlots() }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Array(entries.values)) {
            persistence.set(.favoriteEntries, data)
        }
    }

    private func saveWidgetSlots() {
        let flat = widgetSlotIdsByCity.mapValues { $0.map { $0 ?? "" } }
        if let data = try? JSONEncoder().encode(flat) {
            persistence.set(.favoriteWidgetSlots, data)
        }
    }

    private func load() {
        if let data = persistence.get(.favoriteWidgetSlots),
           let flat = try? JSONDecoder().decode([String: [String]].self, from: data) {
            widgetSlotIdsByCity = flat.mapValues { $0.map { $0.isEmpty ? nil : $0 } }
        }
        if let data = persistence.get(.favoriteEntries),
           let array = try? JSONDecoder().decode([FavoriteEntry].self, from: data) {
            entries = Dictionary(uniqueKeysWithValues: array.map { ($0.stationId, $0) })
        }
    }
}
