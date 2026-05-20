import Foundation
import Observation

@Observable
class CityStore: NSObject, URLSessionDelegate {
    var selectedCity: City
    var hasCompletedOnboarding: Bool
    var cities: [City] = City.staticAll
    var isLoadingCities: Bool = false

    @ObservationIgnored private let cityKey = "selected_city_id"
    @ObservationIgnored private let onboardingKey = "has_completed_onboarding"
    @ObservationIgnored private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    // CityBike network IDs that overlap with our static cities (skip to avoid duplicates)
    @ObservationIgnored private static let excludedCitybikeIds: Set<String> = [
        "vlille", "velib", "velam", "velocite-besancon", "villo", "velo2",
        "dublinbikes", "bysykkel-lillestrom", "bicikelj", "lundahoj", "veloh",
        "velov", "mbajk", "velocite-mulhouse", "velostanlib", "li-bia-velo",
        "bicloo", "toyama-cyclocity", "velo", "libelo", "nomago-ljubljana",
        "vilnius-cyclocity", "chantrerie-captainbike", "sevici", "valenbisi"
    ]

    override init() {
        let savedId = UserDefaults.standard.string(forKey: "selected_city_id") ?? ""
        self.selectedCity = City.staticAll.first { $0.id == savedId } ?? City.staticAll[0]
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    }

    func selectCity(_ city: City) {
        selectedCity = city
        UserDefaults.standard.set(city.id, forKey: cityKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    // MARK: - Dynamic CityBike loading

    func loadCitybikeNetworks() async {
        if let cached = loadCitybikeCacheIfValid() {
            await mergeCitybike(cached)
            return
        }
        await fetchCitybikeNetworks()
    }

    private func fetchCitybikeNetworks() async {
        await MainActor.run { isLoadingCities = true }
        guard let url = URL(string: "https://api.citybik.es/v2/networks") else { return }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(CitybikeNetworkListResponse.self, from: data)
            saveCitybikeCache(data)
            await mergeCitybike(response.networks)
        } catch {
            print("⚠️ [CityBike] Failed to load networks: \(error)")
        }
        await MainActor.run { isLoadingCities = false }
    }

    // MARK: - URLSessionDelegate (TLS bypass for corporate proxy / Zscaler)

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        var error: CFError?
        SecTrustEvaluateWithError(trust, &error)
        completionHandler(.useCredential, URLCredential(trust: trust))
    }

    @MainActor
    private func mergeCitybike(_ networks: [CitybikeNetworkEntry]) {
        let dynamic = networks
            .filter { !Self.excludedCitybikeIds.contains($0.id) }
            .map { $0.toCity() }

        let merged = (City.staticAll + dynamic)
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        cities = merged

        if let found = merged.first(where: { $0.id == selectedCity.id }) {
            selectedCity = found
        }
        isLoadingCities = false
    }

    // MARK: - Cache (24h)

    private var cacheURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("citybike_networks.json")
    }

    private func saveCitybikeCache(_ data: Data) {
        guard let url = cacheURL else { return }
        try? data.write(to: url)
    }

    private func loadCitybikeCacheIfValid() -> [CitybikeNetworkEntry]? {
        guard let url = cacheURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < 86_400,
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(CitybikeNetworkListResponse.self, from: data)
        else { return nil }
        return response.networks
    }
}
