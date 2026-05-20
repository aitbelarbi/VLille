import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class LiveActivityManager {
    private var currentActivity: Activity<TripActivityAttributes>?

    var isActive: Bool { currentActivity != nil }

    func start(
        tripDisplayName: String,
        originName: String,
        destinationName: String,
        departureDate: Date,
        bikesAvailable: Int? = nil
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        Task {
            await endCurrentActivity()
            let attributes = TripActivityAttributes(
                tripDisplayName: tripDisplayName,
                originName: originName,
                destinationName: destinationName
            )
            let state = TripActivityAttributes.ContentState(
                departureDate: departureDate,
                bikesAvailable: bikesAvailable
            )
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: departureDate.addingTimeInterval(1800))
                )
                print("✅ Live Activity started: \(currentActivity?.id ?? "nil")")
            } catch {
                print("❌ Live Activity failed: \(error)")
            }
        }
    }

    func update(bikesAvailable: Int?) async {
        guard let activity = currentActivity else { return }
        let newState = TripActivityAttributes.ContentState(
            departureDate: activity.content.state.departureDate,
            bikesAvailable: bikesAvailable
        )
        await activity.update(
            .init(state: newState, staleDate: activity.content.state.departureDate.addingTimeInterval(1800))
        )
    }

    func end() {
        Task { await endCurrentActivity() }
    }

    private func endCurrentActivity() async {
        await currentActivity?.end(dismissalPolicy: .immediate)
        await MainActor.run { currentActivity = nil }
    }
}
