import Foundation

// MARK: - AppKey

struct AppKey<T> {
    let rawValue: String
    init(_ rawValue: String) { self.rawValue = rawValue }
}

// MARK: - Keys: App Group

extension AppKey where T == Bool {
    static let hasCompletedOnboarding = AppKey("has_completed_onboarding")
    static let isPremium              = AppKey("is_premium")
    static let ratingCompleted        = AppKey("rating_has_completed")
}

extension AppKey where T == Int {
    static let ratingLaunchCount = AppKey("rating_launch_count")
}

extension AppKey where T == String {
    static let selectedCityId       = AppKey("selected_city_id")
    static let userProfile          = AppKey("user_profile")
    static let cachedWeatherSymbol  = AppKey("cached_weather_symbol")
    static let cachedWeatherTemp    = AppKey("cached_weather_temp")
}

extension AppKey where T == Data {
    static let selectedCustomCity  = AppKey("selected_custom_city")
    static let savedAddresses      = AppKey("saved_addresses")
    static let addressWidgetSlots  = AppKey("address_widget_slot_ids")
    static let favoriteEntries     = AppKey("favorite_entries_v2")
    static let favoriteWidgetSlots = AppKey("widget_slot_ids")
    static let savedTrips          = AppKey("saved_trips")
}

extension AppKey where T == [String] {
    static let ghostReportedCities = AppKey("ghost_reported_cities")
}

extension AppKey where T == Double {
    static func weatherLastFetch(cityId: String) -> AppKey { AppKey("weather_last_fetch_\(cityId)") }
}

// MARK: - PersistenceStore

final class PersistenceStore {
    static let shared = PersistenceStore()

    private let defaults: UserDefaults

    private init() {
        self.defaults = UserDefaults(suiteName: "group.com.insightiq.Vely") ?? .standard
    }

    func get<T>(_ key: AppKey<T>, default value: T) -> T {
        defaults.object(forKey: key.rawValue) as? T ?? value
    }

    func get<T>(_ key: AppKey<T>) -> T? {
        defaults.object(forKey: key.rawValue) as? T
    }

    func set<T>(_ key: AppKey<T>, _ value: T) {
        defaults.set(value, forKey: key.rawValue)
    }

    func remove<T>(_ key: AppKey<T>) {
        defaults.removeObject(forKey: key.rawValue)
    }
}
