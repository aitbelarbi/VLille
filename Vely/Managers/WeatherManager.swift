import Foundation
import WeatherKit
import CoreLocation
import Observation

@Observable
@MainActor
final class WeatherManager {
    var current: CurrentWeather?
    var hourly: [HourWeather] = []
    var attribution: WeatherAttribution?
    var isLoading = false
    var hasError = false

    @ObservationIgnored private let service = WeatherService.shared
    @ObservationIgnored private let cacheKeyPrefix = "weather_last_fetch_"
    @ObservationIgnored private let cacheDuration: TimeInterval = 6 * 3600
    @ObservationIgnored private let appGroupDefaults = UserDefaults(suiteName: "group.com.insightiq.Vely")

    // Garde en mémoire la ville actuellement chargée pour éviter les doubles fetches
    @ObservationIgnored private var cachedCityId: String?

    func fetch(latitude: Double, longitude: Double, cityId: String) async {
        let cacheKey = cacheKeyPrefix + cityId
        let lastFetch = UserDefaults.standard.double(forKey: cacheKey)
        let elapsed = Date().timeIntervalSince1970 - lastFetch

        // Skip si même ville et données récentes (< 6h)
        if cachedCityId == cityId, elapsed < cacheDuration {
            return
        }

        isLoading = true
        hasError = false
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            async let weatherRequest     = service.weather(for: location)
            async let attributionRequest = service.attribution
            let (weather, attr) = try await (weatherRequest, attributionRequest)
            current     = weather.currentWeather
            hourly      = Array(weather.hourlyForecast.filter { $0.date >= Date() }.prefix(24))
            attribution = attr
            cachedCityId = cityId
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheKey)
            let tempStr = weather.currentWeather.temperature.formatted(.measurement(width: .narrow, usage: .weather))
            appGroupDefaults?.set(weather.currentWeather.symbolName, forKey: "cached_weather_symbol")
            appGroupDefaults?.set(tempStr, forKey: "cached_weather_temp")
        } catch {
            hasError = true
        }
        isLoading = false
    }
}
