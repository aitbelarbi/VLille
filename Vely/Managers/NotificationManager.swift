import UserNotifications
import Observation

@Observable
final class NotificationManager {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init() {
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run { authorizationStatus = settings.authorizationStatus }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            await refreshStatus()
            return granted
        } catch {
            return false
        }
    }

    func schedule(_ trip: Trip) {
        guard let leadMinutes = trip.notificationLeadMinutes else { return }
        cancel(tripId: trip.id)

        let content = UNMutableNotificationContent()
        content.title = trip.name.isEmpty
            ? NSLocalizedString("trip_notification_title", comment: "")
            : trip.name
        content.body = String(
            format: NSLocalizedString("trip_notification_body", comment: ""),
            leadMinutes
        )
        content.sound = .default

        for day in trip.schedule.days {
            let totalMinutes = trip.schedule.departureHour * 60 + trip.schedule.departureMinute - leadMinutes
            let hour = ((totalMinutes / 60) % 24 + 24) % 24
            let minute = ((totalMinutes % 60) + 60) % 60

            var components = DateComponents()
            components.weekday = day.rawValue
            components.hour = hour
            components.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let identifier = "\(trip.id.uuidString)-\(day.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancel(tripId: UUID) {
        let prefix = tripId.uuidString
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
