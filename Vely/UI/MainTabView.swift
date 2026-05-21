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
    @Environment(ProfileStore.self) var profileStore
    @State private var selectedTab = 0
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var navigateToTrips = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("tab_map", systemImage: "map", value: 0) {
                    MapView(viewModel: viewModel, cameraPosition: $cameraPosition)
                }
                if selectedTab != 2 {
                    Tab("tab_favorites", systemImage: "star", value: 1) {
                        FavoritesView(viewModel: viewModel, selectedTab: $selectedTab, cameraPosition: $cameraPosition, navigateToTrips: $navigateToTrips)
                    }
                }
                Tab("tab_search", systemImage: "magnifyingglass", value: 2, role: .search) {
                    SearchView(viewModel: viewModel, selectedTab: $selectedTab, cameraPosition: $cameraPosition)
                }
            }
            .task {
                print("[Onboarding] MainTabView.task — cityStore.hasCompletedOnboarding=\(cityStore.hasCompletedOnboarding)")
                cameraPosition = .region(MKCoordinateRegion(
                    center: cityStore.selectedCity.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
                if profileStore.strategy.shouldLoadStations {
                    viewModel.switchCity(to: cityStore.selectedCity)
                    await viewModel.startAutoRefresh()
                }
            }
            .onChange(of: cityStore.selectedCity) { _, newCity in
                if profileStore.strategy.shouldLoadStations {
                    viewModel.switchCity(to: newCity)
                    Task { await viewModel.startAutoRefresh() }
                }
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: newCity.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
            .onChange(of: profileStore.profile) { _, _ in
                if profileStore.strategy.shouldLoadStations {
                    viewModel.switchCity(to: cityStore.selectedCity)
                    Task { await viewModel.startAutoRefresh() }
                } else {
                    viewModel.stopAndClear()
                }
            }

            if !cityStore.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .onAppear {
                        print("[Onboarding] OnboardingView appeared — cityStore.hasCompletedOnboarding=\(cityStore.hasCompletedOnboarding)")
                    }
            }
        }
        .animation(.easeInOut, value: cityStore.hasCompletedOnboarding)
        .onOpenURL { url in
            guard url.scheme == "vely", url.host == "trips" else { return }
            selectedTab = 1
            navigateToTrips = true
        }
        .sheet(isPresented: Binding(
            get: { ratingManager.shouldShowPrompt },
            set: { if !$0 { ratingManager.dismissWithoutAction() } }
        )) {
            RatingPromptView()
        }
    }

}
