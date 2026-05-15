//
//  VelyApp.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 13/02/2025.
//

import SwiftUI

@main
struct VelyApp: App {
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(favoritesStore)
                .environmentObject(locationManager)
        }
    }
}
