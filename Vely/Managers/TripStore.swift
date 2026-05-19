import Observation
import Foundation

@Observable
final class TripStore {
    private(set) var trips: [Trip] = []
    @ObservationIgnored private let defaults = UserDefaults(suiteName: "group.com.insightiq.Vely") ?? .standard
    @ObservationIgnored private let key = "saved_trips"

    init() { load() }

    func add(_ trip: Trip) {
        trips.append(trip)
        save()
    }

    func remove(at offsets: IndexSet) {
        trips.remove(atOffsets: offsets)
        save()
    }

    func update(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index] = trip
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(trips) {
            defaults.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let saved = try? JSONDecoder().decode([Trip].self, from: data) else { return }
        trips = saved
    }
}
