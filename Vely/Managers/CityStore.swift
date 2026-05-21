import Foundation
import Observation

@Observable
class CityStore: NSObject, URLSessionDelegate {
    var selectedCity: City
    var hasCompletedOnboarding: Bool
    var cities: [City] = City.staticAll
    var isLoadingCities: Bool = false

    @ObservationIgnored private let persistence = PersistenceStore.shared

    private struct CustomCityData: Codable {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double
        let countryCode: String

        var toCity: City {
            City(id: id, name: name, latitude: latitude, longitude: longitude,
                 provider: .unsupported, serviceName: "", countryCode: countryCode)
        }
    }
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
        let p = PersistenceStore.shared
        let savedId = p.get(.selectedCityId, default: "")
        if let city = City.staticAll.first(where: { $0.id == savedId }) {
            self.selectedCity = city
        } else if let data = p.get(.selectedCustomCity),
                  let custom = try? JSONDecoder().decode(CustomCityData.self, from: data),
                  custom.id == savedId {
            self.selectedCity = custom.toCity
        } else {
            self.selectedCity = City.staticAll[0]
        }
        self.hasCompletedOnboarding = p.get(.hasCompletedOnboarding, default: false)
    }

    func selectCity(_ city: City) {
        selectedCity = city
        persistence.set(.selectedCityId, city.id)
        if !city.provider.isSupported {
            let data = try? JSONEncoder().encode(CustomCityData(
                id: city.id, name: city.name,
                latitude: city.latitude, longitude: city.longitude,
                countryCode: city.countryCode
            ))
            persistence.set(.selectedCustomCity, data ?? Data())
        } else {
            persistence.remove(.selectedCustomCity)
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        persistence.set(.hasCompletedOnboarding, true)
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
