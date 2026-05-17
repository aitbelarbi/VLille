import Foundation
import Observation

@Observable
class CityStore {
    var selectedCity: City
    var hasCompletedOnboarding: Bool

    @ObservationIgnored private let cityKey = "selected_city_id"
    @ObservationIgnored private let onboardingKey = "has_completed_onboarding"

    init() {
        let savedId = UserDefaults.standard.string(forKey: "selected_city_id") ?? "lille"
        self.selectedCity = City.all.first { $0.id == savedId } ?? .lille
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
}
