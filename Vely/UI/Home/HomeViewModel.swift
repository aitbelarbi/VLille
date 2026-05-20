import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
final class HomeViewModel {
    var stations: [BikeStation] = []
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?
    private var currentCity: City?
    var pendingStationToShow: BikeStation?

    @ObservationIgnored private let repository = StationRepository()
    @ObservationIgnored private var currentRequestId = UUID()
    @ObservationIgnored private var autoRefreshTask: Task<Void, Never>?

    func switchCity(to city: City) {
        currentRequestId = UUID()
        autoRefreshTask?.cancel()
        currentCity = city
        stations = []
        errorMessage = nil
        fetchStations()
    }

    func startAutoRefresh() async {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task {
            await loadStations()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                await loadStations()
            }
        }
        await autoRefreshTask?.value
    }

    func fetchStations() {
        Task { await loadStations() }
    }

    func stopAndClear() {
        currentRequestId = UUID()
        autoRefreshTask?.cancel()
        stations = []
        errorMessage = nil
        isLoading = false
    }

    func dismissError() { errorMessage = nil }

    private func loadStations() async {
        guard let city = currentCity else { return }
        let requestId = currentRequestId
        isLoading = true
        do {
            let result = try await repository.fetch(city: city)
            guard currentRequestId == requestId else { return }
            stations = result
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            guard currentRequestId == requestId else { return }
            errorMessage = String(localized: "error_network")
        }
        guard currentRequestId == requestId else { return }
        isLoading = false
        WidgetCenter.shared.reloadAllTimelines()
    }
}
