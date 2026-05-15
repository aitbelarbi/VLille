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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(favoritesStore)
                .environment(locationManager)
        }
    }
}
