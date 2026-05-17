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
    @State private var cityStore = CityStore()
    @State private var ratingManager = RatingManager()
    @State private var weatherManager = WeatherManager()
    @State private var ghostCityManager = GhostCityManager()
    @AppStorage("app_color_scheme") private var colorSchemePreference = "auto"
    @AppStorage("app_locale") private var appLocale = ""

    var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(favoritesStore)
                .environment(locationManager)
                .environment(cityStore)
                .environment(ratingManager)
                .environment(weatherManager)
                .environment(ghostCityManager)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.locale, appLocale.isEmpty ? .current : Locale(identifier: appLocale))
                .task {
                    ratingManager.recordLaunch()
                    await cityStore.loadCitybikeNetworks()
                }
        }
    }
}
