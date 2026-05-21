import Observation
import Foundation

@Observable
final class TripStore {
    private(set) var trips: [Trip] = []
    @ObservationIgnored private let persistence = PersistenceStore.shared

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
            persistence.set(.savedTrips, data)
        }
    }

    private func load() {
        guard let data = persistence.get(.savedTrips),
              let saved = try? JSONDecoder().decode([Trip].self, from: data) else { return }
        trips = saved
    }
}
