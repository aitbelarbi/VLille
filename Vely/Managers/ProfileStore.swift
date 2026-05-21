import Observation
import Foundation
import WidgetKit

@Observable
final class ProfileStore {
    private(set) var profile: UserProfile = .bikesharing
    @ObservationIgnored private let persistence = PersistenceStore.shared

    var strategy: any ProfileStrategy {
        switch profile {
        case .bikesharing: BikesharingStrategy()
        case .cyclist: CyclistStrategy()
        }
    }

    init() {
        if let raw = PersistenceStore.shared.get(.userProfile),
           let p = UserProfile(rawValue: raw) {
            profile = p
        }
    }

    func setProfile(_ profile: UserProfile) {
        self.profile = profile
        persistence.set(.userProfile, profile.rawValue)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
