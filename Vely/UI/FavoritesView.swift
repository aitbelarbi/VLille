//
//  FavoritesView.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 15/05/2026.
//

import SwiftUI
import MapKit

struct FavoritesView: View {
    var viewModel: HomeViewModel
    @Environment(FavoritesStore.self) var favoritesStore
    @Binding var selectedTab: Int
    @Binding var cameraPosition: MapCameraPosition
    @State private var selectedStation: BikeStation?

    var favoriteStations: [BikeStation] {
        viewModel.stations.filter { favoritesStore.isFavorite($0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteStations.isEmpty {
                    ContentUnavailableView(
                        "favorites_empty_title",
                        systemImage: "star.slash",
                        description: Text("favorites_empty_hint")
                    )
                } else {
                    List(favoriteStations) { station in
                        Button {
                            goToStation(station)
                        } label: {
                            StationRowView(station: station)
                        }
                        .buttonStyle(.plain)
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
        selectedTab = 0
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
