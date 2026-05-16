//
//  SearchView.swift
//  Vlille
//

import SwiftUI
import MapKit

struct SearchView: View {
    var viewModel: HomeViewModel
    @Environment(FavoritesStore.self) var favoritesStore
    @Binding var selectedTab: Int
    @Binding var cameraPosition: MapCameraPosition

    @State private var query = ""
    @State private var localSearchResults: [MKMapItem] = []
    @State private var isSearchingPlaces = false

    var filteredStations: [VLilleStation] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return viewModel.stations.filter {
            $0.nom.lowercased().contains(q) ||
            $0.adresse.lowercased().contains(q) ||
            ($0.commune?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !filteredStations.isEmpty {
                    Section("home_title") {
                        ForEach(filteredStations) { station in
                            Button { goToStation(station) } label: {
                                StationRowView(station: station)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Résultats lieux / adresses
                if !localSearchResults.isEmpty {
                    Section("search_places_title") {
                        ForEach(localSearchResults, id: \.self) { item in
                            Button { goToPlace(item) } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "")
                                        .font(.headline)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // État vide
                if query.isEmpty {
                    ContentUnavailableView(
                        "search_empty_title",
                        systemImage: "magnifyingglass",
                        description: Text("search_empty_hint")
                    )
                } else if filteredStations.isEmpty && localSearchResults.isEmpty && !isSearchingPlaces {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("tab_search")
            .searchable(text: $query, prompt: LocalizedStringKey("search_placeholder"))
            .onChange(of: query) { _, newValue in
                searchPlaces(newValue)
            }
        }
    }

    private func searchPlaces(_ text: String) {
        guard !text.isEmpty else {
            localSearchResults = []
            return
        }
        isSearchingPlaces = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.6292, longitude: 3.0573),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        Task {
            let results = try? await MKLocalSearch(request: request).start()
            await MainActor.run {
                localSearchResults = results?.mapItems.filter { item in
                    item.placemark.countryCode == "FR"
                } ?? []
                isSearchingPlaces = false
            }
        }
    }

    private func goToStation(_ station: VLilleStation) {
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: station.y, longitude: station.x),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        selectedTab = 0
    }

    private func goToPlace(_ item: MKMapItem) {
        cameraPosition = .region(MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        selectedTab = 0
    }
}
