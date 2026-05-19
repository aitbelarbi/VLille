import Observation
import Foundation

@Observable
final class ProfileStore {
    private(set) var profile: UserProfile = .bikesharing
    @ObservationIgnored private let defaults = UserDefaults(suiteName: "group.com.insightiq.Vely") ?? .standard
    @ObservationIgnored private let key = "user_profile"

    var strategy: any ProfileStrategy {
        switch profile {
        case .bikesharing: BikesharingStrategy()
        case .cyclist: CyclistStrategy()
        }
    }

    init() {
        if let raw = defaults.string(forKey: key),
           let p = UserProfile(rawValue: raw) {
            profile = p
        }
    }

    func setProfile(_ profile: UserProfile) {
        self.profile = profile
        defaults.set(profile.rawValue, forKey: key)
    }
}
