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
    private(set) var widgetSlotIds: [String?] = [nil, nil]
    private(set) var savedAddresses: [SavedAddress] = []

    @ObservationIgnored private let entriesKey = "favorite_entries_v2"
    @ObservationIgnored private let legacyKey = "favorite_station_ids"
    @ObservationIgnored private let widgetSlotsKey = "widget_slot_ids"
    @ObservationIgnored private let addressesKey = "saved_addresses"
    @ObservationIgnored private let defaults = UserDefaults(suiteName: "group.com.insightiq.Vely")!

    init() {
        load()
    }

    func isFavorite(_ station: BikeStation) -> Bool {
        entries[station.id] != nil
    }

    func widgetSlot(for stationId: String) -> Int? {
        if widgetSlotIds[0] == stationId { return 1 }
        if widgetSlotIds[1] == stationId { return 2 }
        return nil
    }

    func setWidgetSlot(_ index: Int, stationId: String?) {
        guard index < 2 else { return }
        // Si la station est déjà dans l'autre slot, on la retire
        let otherIndex = index == 0 ? 1 : 0
        if let id = stationId, widgetSlotIds[otherIndex] == id {
            widgetSlotIds[otherIndex] = nil
        }
        widgetSlotIds[index] = stationId
        saveWidgetSlots()
    }

    @discardableResult
    func toggle(_ station: BikeStation) -> Bool {
        if entries[station.id] != nil {
            // Retirer des slots widget si présent
            for i in 0..<2 where widgetSlotIds[i] == station.id {
                widgetSlotIds[i] = nil
            }
            saveWidgetSlots()
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
        for i in 0..<2 where widgetSlotIds[i] == stationId {
            widgetSlotIds[i] = nil
        }
        saveWidgetSlots()
        entries.removeValue(forKey: stationId)
        save()
    }

    func addAddress(_ address: SavedAddress) {
        savedAddresses.append(address)
        saveAddresses()
    }

    func removeAddress(id: UUID) {
        savedAddresses.removeAll { $0.id == id }
        saveAddresses()
    }

    func updateAddress(_ address: SavedAddress) {
        guard let index = savedAddresses.firstIndex(where: { $0.id == address.id }) else { return }
        savedAddresses[index] = address
        saveAddresses()
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

    private func saveAddresses() {
        if let data = try? JSONEncoder().encode(savedAddresses) {
            defaults.set(data, forKey: addressesKey)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Array(entries.values)) {
            defaults.set(data, forKey: entriesKey)
        }
    }

    private func saveWidgetSlots() {
        let slots = widgetSlotIds.map { $0 ?? "" }
        if let data = try? JSONEncoder().encode(slots) {
            defaults.set(data, forKey: widgetSlotsKey)
        }
    }

    private func load() {
        // Charger les slots widget
        if let data = defaults.data(forKey: widgetSlotsKey),
           let slots = try? JSONDecoder().decode([String].self, from: data) {
            widgetSlotIds = slots.map { $0.isEmpty ? nil : $0 }
        }

        // Charger les adresses
        if let data = defaults.data(forKey: addressesKey),
           let addresses = try? JSONDecoder().decode([SavedAddress].self, from: data) {
            savedAddresses = addresses
        }

        // Charger les entrées
        if let data = defaults.data(forKey: entriesKey),
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
