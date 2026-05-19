import SwiftUI
import CoreLocation

// MARK: - SavedAddress

struct SavedAddress: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
}

extension SavedAddress {
    var systemIcon: String {
        let lower = name.lowercased()
        if lower.contains("maison") || lower.contains("home") || lower.contains("domicile") || lower.contains("chez moi") { return "house.fill" }
        if lower.contains("boulot") || lower.contains("travail") || lower.contains("work") || lower.contains("bureau") { return "briefcase.fill" }
        return "mappin.circle.fill"
    }

    var tintColor: Color {
        let lower = name.lowercased()
        if lower.contains("maison") || lower.contains("home") || lower.contains("domicile") || lower.contains("chez moi") { return .orange }
        if lower.contains("boulot") || lower.contains("travail") || lower.contains("work") || lower.contains("bureau") { return .blue }
        return .indigo
    }
}

// MARK: - Protocol

protocol FavoriteItem: Identifiable {
    var id: String { get }
    var displayName: String { get }
    var subtitle: String { get }
    var coordinate: CLLocationCoordinate2D? { get }
    var markerIcon: String { get }
    var markerTint: Color { get }
    var rowLeadingIcon: String { get }
    var rowLeadingBadgeText: String? { get }
    var rowLeadingColor: Color { get }
    var bikesAvailable: Int? { get }
    var docksAvailable: Int? { get }
    var widgetSlot: Int? { get }
    var isActive: Bool { get }
    var liveStationReference: BikeStation? { get }
    func remove(from store: FavoritesStore)
}

extension FavoriteItem {
    var rowLeadingBadgeText: String? { nil }
    var bikesAvailable: Int? { nil }
    var docksAvailable: Int? { nil }
    var widgetSlot: Int? { nil }
    var isActive: Bool { true }
    var liveStationReference: BikeStation? { nil }
}

// MARK: - StationFavorite

struct StationFavorite: FavoriteItem {
    let entry: FavoriteEntry
    let liveStation: BikeStation?
    let slot: Int?

    var id: String { entry.stationId }
    var displayName: String { entry.stationName.isEmpty ? entry.stationId : entry.stationName }
    var subtitle: String { entry.stationAddress }
    var coordinate: CLLocationCoordinate2D? {
        guard let s = liveStation else { return nil }
        return CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude)
    }
    var markerIcon: String { "bicycle" }
    var markerTint: Color {
        guard let s = liveStation else { return .secondary }
        guard s.isOperational else { return .red }
        return s.bikesAvailable > 0 ? .green : .orange
    }
    var rowLeadingIcon: String { "bicycle" }
    var rowLeadingBadgeText: String? { liveStation.map { "\($0.bikesAvailable)" } }
    var rowLeadingColor: Color { markerTint }
    var bikesAvailable: Int? { liveStation?.bikesAvailable }
    var docksAvailable: Int? { liveStation?.docksAvailable }
    var widgetSlot: Int? { slot }
    var isActive: Bool { liveStation != nil }
    var liveStationReference: BikeStation? { liveStation }

    func remove(from store: FavoritesStore) {
        store.remove(stationId: entry.stationId)
    }
}

// MARK: - AddressFavorite

struct AddressFavorite: FavoriteItem {
    let address: SavedAddress

    var id: String { address.id.uuidString }
    var displayName: String { address.name }
    var subtitle: String { address.address }
    var coordinate: CLLocationCoordinate2D? {
        CLLocationCoordinate2D(latitude: address.latitude, longitude: address.longitude)
    }
    var markerIcon: String { address.systemIcon }
    var markerTint: Color { address.tintColor }
    var rowLeadingIcon: String { address.systemIcon }
    var rowLeadingColor: Color { address.tintColor }

    func remove(from store: FavoritesStore) {
        store.removeAddress(id: address.id)
    }
}
