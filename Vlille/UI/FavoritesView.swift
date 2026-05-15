//
//  FavoritesView.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 15/05/2026.
//

import SwiftUI
import MapKit

struct FavoritesView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var favoritesStore: FavoritesStore
    @Binding var selectedTab: Int
    @Binding var cameraPosition: MapCameraPosition
    @State private var selectedStation: VLilleStation?

    var favoriteStations: [VLilleStation] {
        viewModel.stations.filter { favoritesStore.isFavorite($0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteStations.isEmpty {
                    ContentUnavailableView(
                        "Aucun favori",
                        systemImage: "star.slash",
                        description: Text("Ajoutez des stations en favoris depuis la carte.")
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
            .navigationTitle("Favoris")
            .sheet(item: $selectedStation) { station in
                StationDetailView(station: station)
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func goToStation(_ station: VLilleStation) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: station.y, longitude: station.x),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        )
        selectedTab = 0
    }
}

struct StationRowView: View {
    let station: VLilleStation

    var statusColor: Color {
        guard station.etat == "EN SERVICE" else { return .red }
        return station.nbVelosDispo > 0 ? .green : .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 40, height: 40)
                Text("\(station.nbVelosDispo)")
                    .font(.callout.bold())
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(station.nom)
                    .font(.headline)
                Text(station.adresse)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Image(systemName: "bicycle")
                        .font(.subheadline)
                    Text("\(station.nbVelosDispo)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.green)
                
                VStack(spacing: 2) {
                    Image(systemName: "parkingsign")
                        .font(.subheadline)
                    Text("\(station.nbPlacesDispo)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}
