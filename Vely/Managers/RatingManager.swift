import Foundation
import Observation

@Observable
final class RatingManager {
    @ObservationIgnored private let persistence = PersistenceStore.shared

    var shouldShowPrompt = false

    private var launchCount: Int {
        get { persistence.get(.ratingLaunchCount, default: 0) }
        set { persistence.set(.ratingLaunchCount, newValue) }
    }

    private var hasCompleted: Bool {
        get { persistence.get(.ratingCompleted, default: false) }
        set { persistence.set(.ratingCompleted, newValue) }
    }

    func recordLaunch() {
        launchCount += 1
        if launchCount >= 5, !hasCompleted {
            shouldShowPrompt = true
        }
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
