import UserNotifications
import Observation

@Observable
final class NotificationManager: NSObject {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var onTripNotificationTap: ((String, String, String, Date) -> Void)?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
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

    func schedule(_ trip: Trip, originName: String? = nil, destinationName: String? = nil, includesWeather: Bool = false) {
        guard let leadMinutes = trip.notificationLeadMinutes else { return }
        cancel(tripId: trip.id)

        let content = UNMutableNotificationContent()
        content.title = {
            if !trip.name.isEmpty { return trip.name }
            if let o = originName, let d = destinationName { return "\(o) → \(d)" }
            return NSLocalizedString("trip_notification_title", comment: "")
        }()
        content.body = {
            let base = String(format: NSLocalizedString("trip_notification_body", comment: ""), leadMinutes)
            if includesWeather,
               let temp = UserDefaults(suiteName: "group.com.insightiq.Vely")?.string(forKey: "cached_weather_temp") {
                return "\(base) — \(temp)"
            }
            return base
        }()
        content.sound = .default
        content.userInfo = [
            "tripDisplayName": content.title,
            "originName": originName ?? "",
            "destinationName": destinationName ?? "",
            "departureHour": trip.schedule.departureHour,
            "departureMinute": trip.schedule.departureMinute
        ]

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

    #if DEBUG
    func scheduleTest(tripName: String = "", leadMinutes: Int = 15) {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            await refreshStatus()
            let content = UNMutableNotificationContent()
            content.title = tripName.isEmpty
                ? NSLocalizedString("trip_notification_title", comment: "")
                : tripName
            content.body = String(format: NSLocalizedString("trip_notification_body", comment: ""), leadMinutes)
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "debug-test", content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(request)

            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = Calendar.current.component(.hour, from: Date().addingTimeInterval(Double(leadMinutes) * 60))
            components.minute = Calendar.current.component(.minute, from: Date().addingTimeInterval(Double(leadMinutes) * 60))
            let departureDate = Calendar.current.date(from: components) ?? Date().addingTimeInterval(Double(leadMinutes) * 60)
            let displayName = tripName.isEmpty ? NSLocalizedString("trip_notification_title", comment: "") : tripName
            await MainActor.run {
                onTripNotificationTap?(displayName, "Eurallille", "Euratech", departureDate)
            }
        }
    }
    #endif
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        let info = response.notification.request.content.userInfo
        guard let displayName = info["tripDisplayName"] as? String,
              let originName = info["originName"] as? String,
              let destinationName = info["destinationName"] as? String,
              let hour = info["departureHour"] as? Int,
              let minute = info["departureMinute"] as? Int else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        let departureDate = Calendar.current.date(from: components) ?? Date()

        onTripNotificationTap?(displayName, originName, destinationName, departureDate)
    }
}
