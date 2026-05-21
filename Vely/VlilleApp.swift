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
    @State private var liveActivityManager = LiveActivityManager()
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
                .environment(liveActivityManager)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.locale, appLocale.isEmpty ? .current : Locale(identifier: appLocale))
                .onChange(of: purchaseManager.isPremium) { _, isPremium in
                    if !isPremium { liveActivityManager.end() }
                }
                .task {
                    ratingManager.recordLaunch()
                    await cityStore.loadCitybikeNetworks()
                    await purchaseManager.loadProducts()
                    await purchaseManager.updateSubscriptionStatus()
                    notificationManager.onTripNotificationTap = { displayName, originName, destinationName, departureDate in
                        guard purchaseManager.isPremium else { return }
                        let statusKind: StatusKind?
                        switch profileStore.strategy.liveActivityStatusSource {
                        case .weather:
                            let p = PersistenceStore.shared
                            if let symbol = p.get(.cachedWeatherSymbol),
                               let temp = p.get(.cachedWeatherTemp) {
                                statusKind = .weather(symbol: symbol, temp: temp)
                            } else {
                                statusKind = nil
                            }
                        case .bikeCount:
                            statusKind = nil
                        }
                        liveActivityManager.start(
                            tripDisplayName: displayName,
                            originName: originName,
                            destinationName: destinationName,
                            departureDate: departureDate,
                            statusKind: statusKind
                        )
                    }
                    #if DEBUG
                    purchaseManager.debugPremiumOverride = true
                    #endif
                }
        }
    }
}
