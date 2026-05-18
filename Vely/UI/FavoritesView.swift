import SwiftUI
import MapKit

struct FavoritesView: View {
    var viewModel: HomeViewModel
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(CityStore.self) var cityStore
    @Binding var selectedTab: Int
    @Binding var cameraPosition: MapCameraPosition
    @State private var selectedStation: BikeStation?

    var activeFavorites: [BikeStation] {
        viewModel.stations
            .filter { favoritesStore.isFavorite($0) }
            .sorted { $0.name < $1.name }
    }

    var inactiveGroups: [(cityId: String, cityName: String, entries: [FavoriteEntry])] {
        let activeIds = Set(viewModel.stations.map { $0.id })
        let currentCityId = viewModel.currentCity.id

        let inactive = favoritesStore.entries.values.filter {
            !activeIds.contains($0.stationId) && $0.cityId != currentCityId && !$0.cityId.isEmpty
        }

        let grouped = Dictionary(grouping: inactive) { $0.cityId }
        return grouped.map { cityId, entries in
            let name = cityStore.cities.first { $0.id == cityId }?.name ?? cityId
            return (cityId: cityId, cityName: name, entries: entries.sorted { $0.stationName < $1.stationName })
        }
        .sorted { $0.cityName < $1.cityName }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoritesStore.entries.isEmpty {
                    ContentUnavailableView(
                        "favorites_empty_title",
                        systemImage: "star.slash",
                        description: Text("favorites_empty_hint")
                    )
                } else {
                    List {
                        if !activeFavorites.isEmpty {
                            Section(viewModel.currentCity.name) {
                                ForEach(activeFavorites) { station in
                                    Button {
                                        goToStation(station)
                                    } label: {
                                        StationRowView(station: station)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { indexSet in
                                    indexSet.forEach { favoritesStore.remove(stationId: activeFavorites[$0].id) }
                                }
                            }
                        }

                        ForEach(inactiveGroups, id: \.cityId) { group in
                            Section(group.cityName) {
                                ForEach(group.entries) { entry in
                                    InactiveFavoriteRowView(entry: entry)
                                }
                                .onDelete { indexSet in
                                    indexSet.forEach { favoritesStore.remove(stationId: group.entries[$0].stationId) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("tab_favorites")
            .sheet(item: $selectedStation) { station in
                StationDetailView(station: station)
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func goToStation(_ station: BikeStation) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        )
        viewModel.pendingStationToShow = station
        selectedTab = 0
    }
}

struct InactiveFavoriteRowView: View {
    let entry: FavoriteEntry

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bicycle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.stationName.isEmpty ? entry.stationId : entry.stationName)
                    .font(.headline)
                Text(entry.stationAddress.isEmpty ? "—" : entry.stationAddress)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(0.5)
    }
}

struct StationRowView: View {
    let station: BikeStation

    var statusColor: Color {
        guard station.isOperational else { return .red }
        return station.bikesAvailable > 0 ? .green : .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 40, height: 40)
                Text("\(station.bikesAvailable)")
                    .font(.callout.bold())
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.headline)
                Text(station.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Image(systemName: "bicycle")
                        .font(.subheadline)
                    Text("\(station.bikesAvailable)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.green)

                VStack(spacing: 2) {
                    Image(systemName: "parkingsign")
                        .font(.subheadline)
                    Text("\(station.docksAvailable)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}
