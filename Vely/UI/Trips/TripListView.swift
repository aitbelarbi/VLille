import SwiftUI

struct TripListView: View {
    @Environment(TripStore.self) var tripStore
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(WeatherManager.self) var weatherManager
    @Environment(ProfileStore.self) var profileStore
    @Environment(CityStore.self) var cityStore
    @Environment(AddressStore.self) var addressStore
    @Environment(PurchaseManager.self) var purchaseManager
    @Environment(NotificationManager.self) var notificationManager
    let liveStations: [BikeStation]
    let onAdd: () -> Void
    let onShowPaywall: () -> Void

    @State private var editingTrip: Trip?

    private var currentTrips: [Trip] {
        let currentProfile = profileStore.profile
        let cityId = cityStore.selectedCity.id
        return tripStore.trips.filter { trip in
            guard trip.profile == currentProfile else { return false }
            guard trip.profile == .bikesharing else { return true }
            guard case .stationFavorite(let stationId) = trip.origin else { return true }
            return favoritesStore.entries[stationId]?.cityId == cityId
        }
    }

    var body: some View {
        Group {
            if currentTrips.isEmpty {
                emptyState
            } else {
                tripList
            }
        }
        .sheet(item: $editingTrip) { trip in
            TripCreationView(editingTrip: trip)
                .presentationDragIndicator(.visible)
        }
    }

    private var tripList: some View {
        List {
            if !purchaseManager.isPremium {
                Section {
                    PremiumBannerView(
                        icon: "arrow.trianglehead.branch",
                        title: "banner_trips_title",
                        subtitle: "banner_trips_subtitle",
                        onTap: onShowPaywall
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }

            ForEach(currentTrips) { trip in
                TripCardView(
                    trip: trip,
                    originItem: resolveWaypoint(trip.origin),
                    destinationItem: resolveWaypoint(trip.destination),
                    weather: weatherManager.current,
                    isWeatherProfile: !profileStore.strategy.shouldLoadStations,
                    onEdit: {
                        if purchaseManager.isPremium { editingTrip = trip }
                        else { onShowPaywall() }
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTrip(trip)
                    } label: {
                        Label("trip_delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func deleteTrip(_ trip: Trip) {
        notificationManager.cancel(tripId: trip.id)
        guard let index = tripStore.trips.firstIndex(where: { $0.id == trip.id }) else { return }
        tripStore.remove(at: IndexSet(integer: index))
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "arrow.trianglehead.branch")
                    .font(.system(size: 44))
                    .foregroundStyle(.indigo)
            }

            VStack(spacing: 8) {
                Text("trips_empty_title")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text("trips_empty_hint")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
            }

            Button(action: onAdd) {
                Label("trips_add_first", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.indigo, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func resolveWaypoint(_ waypoint: TripWaypoint) -> (any FavoriteItem)? {
        waypoint.resolve(in: FavoriteStores(favorites: favoritesStore, addresses: addressStore), liveStations: liveStations)
    }

}
