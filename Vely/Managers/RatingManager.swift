import Foundation
import Observation

@Observable
final class RatingManager {
    @ObservationIgnored private let launchCountKey  = "rating_launch_count"
    @ObservationIgnored private let hasCompletedKey = "rating_has_completed"

    var shouldShowPrompt = false

    private var launchCount: Int {
        get { UserDefaults.standard.integer(forKey: launchCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: launchCountKey) }
    }

    private var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedKey) }
    }

    func recordLaunch() {
        launchCount += 1
    }

    func recordFavoriteAdded() {
        guard launchCount >= 3, !hasCompleted else { return }
        shouldShowPrompt = true
    }

    func userSatisfied() {
        hasCompleted = true
        shouldShowPrompt = false
    }

    func userWantsToGiveFeedback() {
        hasCompleted = true
        shouldShowPrompt = false
    }

    func dismissWithoutAction() {
        shouldShowPrompt = false
    }
}
