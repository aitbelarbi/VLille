//
//  SearchView.swift
//  Vlille
//

import SwiftUI
import MapKit

struct SearchView: View {
    var viewModel: HomeViewModel
    @Environment(AddressStore.self) var addressStore
    @Environment(CityStore.self) var cityStore
    @Environment(ProfileStore.self) var profileStore
    @Binding var selectedTab: Int
    @Binding var cameraPosition: MapCameraPosition

    @State private var query = ""
    @State private var localSearchResults: [MKMapItem] = []
    @State private var isSearchingPlaces = false
    @State private var pendingAddressItem: IdentifiableMKMapItem?

    var filteredStations: [BikeStation] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return viewModel.stations.filter {
            $0.name.lowercased().contains(q) ||
            $0.address.lowercased().contains(q) ||
            ($0.district?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if profileStore.strategy.searchIncludesStations && !filteredStations.isEmpty {
                    Section("home_title") {
                        ForEach(filteredStations) { station in
                            Button { goToStation(station) } label: {
                                StationRowView(station: station)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !localSearchResults.isEmpty {
                    Section("search_places_title") {
                        ForEach(localSearchResults, id: \.self) { item in
                            Button { handlePlaceTap(item) } label: {
                                HStack {
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
                                    Spacer()
                                    if profileStore.strategy.canAddAddressFavorites {
                                        let saved = isAlreadySaved(item)
                                        Image(systemName: saved ? "star.fill" : "star")
                                            .foregroundStyle(saved ? .orange : .secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

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
            .sheet(item: $pendingAddressItem) { wrapper in
                AddressNamingSheet(mapItem: wrapper.item, cityId: cityStore.selectedCity.id) { address in
                    addressStore.add(address)
                    pendingAddressItem = nil
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func searchPlaces(_ text: String) {
        guard !text.isEmpty else {
            localSearchResults = []
            return
        }
        isSearchingPlaces = true
        let city = cityStore.selectedCity
        let cityCoord = city.coordinate
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = MKCoordinateRegion(
            center: cityCoord,
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
        if #available(iOS 18.0, *) {
            request.regionPriority = .required
        }
        Task {
            let results = try? await MKLocalSearch(request: request).start()
            let cityLocation = CLLocation(latitude: cityCoord.latitude, longitude: cityCoord.longitude)
            await MainActor.run {
                localSearchResults = (results?.mapItems ?? []).filter { item in
                    guard item.placemark.isoCountryCode?.uppercased() == city.countryCode.uppercased() else { return false }
                    let loc = CLLocation(
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude
                    )
                    return cityLocation.distance(from: loc) < 30_000
                }
                isSearchingPlaces = false
            }
        }
    }

    private func goToStation(_ station: BikeStation) {
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        selectedTab = 0
    }

    private func handlePlaceTap(_ item: MKMapItem) {
        if profileStore.strategy.canAddAddressFavorites && !isAlreadySaved(item) {
            pendingAddressItem = IdentifiableMKMapItem(item)
        } else {
            cameraPosition = .region(MKCoordinateRegion(
                center: item.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
            selectedTab = 0
        }
    }

    private func isAlreadySaved(_ item: MKMapItem) -> Bool {
        let coord = item.placemark.coordinate
        return addressStore.savedAddresses.contains {
            abs($0.latitude - coord.latitude) < 0.0001 &&
            abs($0.longitude - coord.longitude) < 0.0001
        }
    }
}

// MARK: - MKMapItem wrapper

struct IdentifiableMKMapItem: Identifiable {
    let id = UUID()
    let item: MKMapItem
    init(_ item: MKMapItem) { self.item = item }
}

// MARK: - AddressNamingSheet

struct AddressNamingSheet: View {
    let mapItem: MKMapItem
    let cityId: String
    let onSave: (SavedAddress) -> Void

    @State private var name = ""
    @Environment(\.dismiss) private var dismiss

    private var addressString: String {
        mapItem.placemark.title ?? ""
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(mapItem.name ?? addressString)
                        .font(.headline)
                    Text(addressString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("address_save_name_label")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    TextField("address_save_name_placeholder", text: $name)
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

                    HStack(spacing: 8) {
                        QuickNameButton(label: "address_quick_home", icon: "house.fill", color: .orange) { name = String(localized: "address_quick_home") }
                        QuickNameButton(label: "address_quick_work", icon: "briefcase.fill", color: .blue) { name = String(localized: "address_quick_work") }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .navigationTitle("address_save_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common_cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common_done") {
                        let label = name.isEmpty ? (mapItem.name ?? addressString) : name
                        let coord = mapItem.placemark.coordinate
                        onSave(SavedAddress(
                            name: label,
                            address: addressString,
                            latitude: coord.latitude,
                            longitude: coord.longitude,
                            cityId: cityId
                        ))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct QuickNameButton: View {
    let label: LocalizedStringKey
    let icon: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color.opacity(0.12), in: Capsule())
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}
