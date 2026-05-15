//
//  MainTabView.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 15/05/2026.
//

import SwiftUI
import MapKit


struct MainTabView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab = 0
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.6292, longitude: 3.0573),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Carte", systemImage: "map", value: 0) {
                MapView(viewModel: viewModel, cameraPosition: $cameraPosition)
            }
            if selectedTab != 2 {
                Tab("Favoris", systemImage: "star", value: 1) {
                    FavoritesView(viewModel: viewModel, selectedTab: $selectedTab, cameraPosition: $cameraPosition)
                }
            }

            Tab("Recherche", systemImage: "magnifyingglass", value: 2, role: .search) {
                SearchView(viewModel: viewModel, selectedTab: $selectedTab, cameraPosition: $cameraPosition)
            }
        }
        .task {
            await viewModel.startAutoRefresh()
        }
    }
}
