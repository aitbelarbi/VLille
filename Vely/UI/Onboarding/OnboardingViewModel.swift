import MapKit
import Observation

@Observable
@MainActor
final class OnboardingViewModel {
    private(set) var results: [MKMapItem] = []
    private(set) var isSearching = false

    private var searchTask: Task<Void, Never>?

    func search(_ text: String, fallbackFrom staticResults: [City]) {
        searchTask?.cancel()
        results = []
        isSearching = false
        guard text.count >= 2, staticResults.isEmpty else { return }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = text
            request.resultTypes = .address
            let items = (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
            guard !Task.isCancelled else { return }
            var seen = Set<String>()
            results = items
                .filter { $0.placemark.locality != nil || $0.placemark.administrativeArea != nil }
                .filter { seen.insert($0.placemark.locality ?? $0.placemark.administrativeArea ?? "").inserted }
            isSearching = false
        }
    }

    func clear() {
        searchTask?.cancel()
        results = []
        isSearching = false
    }
}
