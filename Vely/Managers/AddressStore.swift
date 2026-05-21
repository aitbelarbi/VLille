import Foundation
import Observation
import WidgetKit

@Observable
final class AddressStore {
    private(set) var savedAddresses: [SavedAddress] = []
    private(set) var widgetSlotIdsByCity: [String: [String?]] = [:]

    @ObservationIgnored private let persistence = PersistenceStore.shared

    init() { load() }

    func add(_ address: SavedAddress) {
        savedAddresses.append(address)
        save()
    }

    func remove(id: UUID) {
        savedAddresses.removeAll { $0.id == id }
        removeFromWidgetSlots(addressId: id.uuidString)
        save()
    }

    func update(_ address: SavedAddress) {
        guard let index = savedAddresses.firstIndex(where: { $0.id == address.id }) else { return }
        savedAddresses[index] = address
        save()
    }

    func widgetSlots(for cityId: String) -> [String?] {
        widgetSlotIdsByCity[cityId] ?? [nil, nil]
    }

    func widgetSlot(for addressId: String, cityId: String) -> Int? {
        let slots = widgetSlots(for: cityId)
        if slots[0] == addressId { return 1 }
        if slots[1] == addressId { return 2 }
        return nil
    }

    func setWidgetSlot(_ index: Int, addressId: String?, cityId: String) {
        var slots = widgetSlots(for: cityId)
        let otherIndex = index == 0 ? 1 : 0
        if let id = addressId, slots[otherIndex] == id {
            slots[otherIndex] = nil
        }
        slots[index] = addressId
        widgetSlotIdsByCity[cityId] = slots
        saveWidgetSlots()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func removeFromWidgetSlots(addressId: String) {
        var changed = false
        for cityId in widgetSlotIdsByCity.keys {
            var slots = widgetSlotIdsByCity[cityId]!
            for i in 0..<2 where slots[i] == addressId {
                slots[i] = nil
                changed = true
            }
            if changed { widgetSlotIdsByCity[cityId] = slots }
        }
        if changed { saveWidgetSlots() }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(savedAddresses) {
            persistence.set(.savedAddresses, data)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveWidgetSlots() {
        let flat = widgetSlotIdsByCity.mapValues { $0.map { $0 ?? "" } }
        if let data = try? JSONEncoder().encode(flat) {
            persistence.set(.addressWidgetSlots, data)
        }
    }

    private func load() {
        if let data = persistence.get(.savedAddresses),
           let saved = try? JSONDecoder().decode([SavedAddress].self, from: data) {
            savedAddresses = saved
        }
        if let data = persistence.get(.addressWidgetSlots),
           let flat = try? JSONDecoder().decode([String: [String]].self, from: data) {
            widgetSlotIdsByCity = flat.mapValues { $0.map { $0.isEmpty ? nil : $0 } }
        }
    }
}
