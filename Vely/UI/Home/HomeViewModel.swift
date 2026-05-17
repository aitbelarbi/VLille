import Foundation
import Observation

@Observable
@MainActor
class HomeViewModel {
    var stations: [BikeStation] = []
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    private let cityStore: CityStore
    private let repository = StationRepository()

    var currentCity: City { cityStore.selectedCity }

    init(cityStore: CityStore) {
        self.cityStore = cityStore
    }

    func switchCity(to city: City) {
        cityStore.selectCity(city)
        stations = []
        errorMessage = nil
        Task { await loadStations() }
    }

    func startAutoRefresh() async {
        await loadStations()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { break }
            await loadStations()
        }
    }

    func dismissError() { errorMessage = nil }

    private func loadStations() async {
        isLoading = true
        do {
            stations = try await repository.fetch(city: currentCity)
            lastUpdated = Date()
        } catch {
            errorMessage = String(localized: "error_network")
        }
        isLoading = false
    }
}
