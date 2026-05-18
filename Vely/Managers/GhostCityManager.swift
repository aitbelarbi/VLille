import Foundation
import Observation

@Observable
final class GhostCityManager {
    var shouldShowPrompt = false
    private(set) var pendingCity: City?

    @ObservationIgnored private let reportedCitiesKey = "ghost_reported_cities"

    private var reportedCities: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: reportedCitiesKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: reportedCitiesKey) }
    }

    func recordEmptyFetch(city: City) {
        guard !reportedCities.contains(city.id) else { return }
        pendingCity = city
        shouldShowPrompt = true
    }

    func userContacted() { close() }
    func dismiss()       { close() }

    private func close() {
        if let city = pendingCity { reportedCities.insert(city.id) }
        shouldShowPrompt = false
        pendingCity = nil
    }
}
