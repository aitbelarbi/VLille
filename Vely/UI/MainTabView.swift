//
//  MainTabView.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 15/05/2026.
//

import SwiftUI
import MapKit

struct MainTabView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(CityStore.self) var cityStore
    @Environment(RatingManager.self) var ratingManager
    @State private var selectedTab = 0
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.6292, longitude: 3.0573),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("tab_map", systemImage: "map", value: 0) {
                    MapView(viewModel: viewModel, cameraPosition: $cameraPosition)
                }
                if selectedTab != 2 {
                    Tab("tab_favorites", systemImage: "star", value: 1) {
                        FavoritesView(viewModel: viewModel, selectedTab: $selectedTab, cameraPosition: $cameraPosition)
                    }
                }
                Tab("tab_search", systemImage: "magnifyingglass", value: 2, role: .search) {
                    SearchView(viewModel: viewModel, selectedTab: $selectedTab, cameraPosition: $cameraPosition)
                }
            }
            .task {
                cameraPosition = .region(MKCoordinateRegion(
                    center: cityStore.selectedCity.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
                viewModel.switchCity(to: cityStore.selectedCity)
                await viewModel.startAutoRefresh()
            }
            .onChange(of: cityStore.selectedCity) { _, newCity in
                viewModel.switchCity(to: newCity)
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: newCity.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }

            if !cityStore.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: cityStore.hasCompletedOnboarding)
        .sheet(isPresented: Binding(
            get: { ratingManager.shouldShowPrompt },
            set: { if !$0 { ratingManager.dismissWithoutAction() } }
        )) {
            RatingPromptView()
        }
    }
}
