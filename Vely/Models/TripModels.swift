import Foundation

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7, sunday = 1

    var id: Int { rawValue }

    var shortName: String {
        Calendar.current.shortWeekdaySymbols[rawValue == 1 ? 0 : rawValue - 1]
    }
}

struct TripSchedule: Codable {
    var days: Set<Weekday>
    var departureHour: Int
    var departureMinute: Int
}

enum TripWaypoint: Codable {
    case stationFavorite(stationId: String)
    case addressFavorite(addressId: UUID)
}

struct Trip: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var schedule: TripSchedule
    var origin: TripWaypoint
    var destination: TripWaypoint
}
