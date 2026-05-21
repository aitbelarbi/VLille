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
    @ObservationIgnored private let persistence = PersistenceStore.shared
    @ObservationIgnored private let cacheDuration: TimeInterval = 6 * 3600

    @ObservationIgnored private var cachedCityId: String?

    func fetch(latitude: Double, longitude: Double, cityId: String) async {
        let cacheKey = AppKey<Double>.weatherLastFetch(cityId: cityId)
        let lastFetch = persistence.get(cacheKey, default: 0)
        let elapsed = Date().timeIntervalSince1970 - lastFetch

        if cachedCityId == cityId, elapsed < cacheDuration { return }

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
            persistence.set(cacheKey, Date().timeIntervalSince1970)
            let tempStr = weather.currentWeather.temperature.formatted(.measurement(width: .narrow, usage: .weather))
            persistence.set(.cachedWeatherSymbol, weather.currentWeather.symbolName)
            persistence.set(.cachedWeatherTemp, tempStr)
        } catch {
            hasError = true
        }
        isLoading = false
    }
}
