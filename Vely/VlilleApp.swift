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
    @State private var addressStore = AddressStore()
    @State private var locationManager = LocationManager()
    @State private var cityStore = CityStore()
    @State private var ratingManager = RatingManager()
    @State private var weatherManager = WeatherManager()
    @State private var ghostCityManager = GhostCityManager()
    @State private var purchaseManager = PurchaseManager()
    @State private var profileStore = ProfileStore()
    @State private var tripStore = TripStore()
    @State private var notificationManager = NotificationManager()
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
                .environment(addressStore)
                .environment(locationManager)
                .environment(cityStore)
                .environment(ratingManager)
                .environment(weatherManager)
                .environment(ghostCityManager)
                .environment(purchaseManager)
                .environment(profileStore)
                .environment(tripStore)
                .environment(notificationManager)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.locale, appLocale.isEmpty ? .current : Locale(identifier: appLocale))
                .task {
                    ratingManager.recordLaunch()
                    await cityStore.loadCitybikeNetworks()
                    await purchaseManager.loadProducts()
                    await purchaseManager.updateSubscriptionStatus()
                    #if DEBUG
                    purchaseManager.debugPremiumOverride = true
                    #endif
                }
        }
    }
}
