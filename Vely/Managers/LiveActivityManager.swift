import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class LiveActivityManager {
    private var currentActivity: Activity<TripActivityAttributes>?
    private var autoEndTask: Task<Void, Never>?

    var isActive: Bool { currentActivity != nil }

    func start(
        tripDisplayName: String,
        originName: String,
        destinationName: String,
        departureDate: Date,
        statusKind: StatusKind? = nil
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        autoEndTask?.cancel()
        Task {
            await endCurrentActivity()
            let attributes = TripActivityAttributes(
                tripDisplayName: tripDisplayName,
                originName: originName,
                destinationName: destinationName
            )
            let state = TripActivityAttributes.ContentState(
                departureDate: departureDate,
                statusKind: statusKind
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
        scheduleAutoEnd(at: departureDate)
    }

    func update(statusKind: StatusKind?) async {
        guard let activity = currentActivity else { return }
        let newState = TripActivityAttributes.ContentState(
            departureDate: activity.content.state.departureDate,
            statusKind: statusKind
        )
        await activity.update(
            .init(state: newState, staleDate: activity.content.state.departureDate.addingTimeInterval(1800))
        )
    }

    func end() {
        autoEndTask?.cancel()
        Task { await endCurrentActivity() }
    }

    private func scheduleAutoEnd(at departureDate: Date) {
        autoEndTask = Task { [weak self] in
            let delay = departureDate.timeIntervalSinceNow + 1800
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }
            await self?.endCurrentActivity()
        }
    }

    private func endCurrentActivity() async {
        await currentActivity?.end(dismissalPolicy: .immediate)
        await MainActor.run { currentActivity = nil }
    }
}
