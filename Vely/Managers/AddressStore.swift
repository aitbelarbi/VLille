import Foundation
import Observation

@Observable
final class AddressStore {
    private(set) var savedAddresses: [SavedAddress] = []

    @ObservationIgnored private let defaults = UserDefaults(suiteName: "group.com.insightiq.Vely") ?? .standard
    @ObservationIgnored private let key = "saved_addresses"

    init() { load() }

    func add(_ address: SavedAddress) {
        savedAddresses.append(address)
        save()
    }

    func remove(id: UUID) {
        savedAddresses.removeAll { $0.id == id }
        save()
    }

    func update(_ address: SavedAddress) {
        guard let index = savedAddresses.firstIndex(where: { $0.id == address.id }) else { return }
        savedAddresses[index] = address
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(savedAddresses) {
            defaults.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let saved = try? JSONDecoder().decode([SavedAddress].self, from: data) else { return }
        savedAddresses = saved
    }
}
