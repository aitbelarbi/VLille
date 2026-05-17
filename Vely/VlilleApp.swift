//
//  VelyApp.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 13/02/2025.
//

import SwiftUI

@main
struct VelyApp: App {
    @State private var favoritesStore = FavoritesStore()
    @State private var locationManager = LocationManager()
    @State private var cityStore: CityStore
    @State private var homeViewModel: HomeViewModel
    @AppStorage("app_color_scheme") private var colorSchemePreference = "auto"
    @AppStorage("app_locale") private var appLocale = ""

    init() {
        let cs = CityStore()
        _cityStore = State(initialValue: cs)
        _homeViewModel = State(initialValue: HomeViewModel(cityStore: cs))
    }

    var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: homeViewModel)
                .environment(favoritesStore)
                .environment(locationManager)
                .environment(cityStore)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.locale, appLocale.isEmpty ? .current : Locale(identifier: appLocale))
                .task { await cityStore.loadCitybikeNetworks() }
        }
    }
}
