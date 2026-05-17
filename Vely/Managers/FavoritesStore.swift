//
//  FavoritesStore.swift
//  Vlille
//

import Foundation
import Observation

@Observable
class FavoritesStore {
    private(set) var favoriteIDs: Set<String> = []
    @ObservationIgnored private let key = "favorite_station_ids"

    init() {
        let saved = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        favoriteIDs = Set(saved)
    }

    func isFavorite(_ station: BikeStation) -> Bool {
        favoriteIDs.contains(station.id)
    }

    func toggle(_ station: BikeStation) {
        if favoriteIDs.contains(station.id) {
            favoriteIDs.remove(station.id)
        } else {
            favoriteIDs.insert(station.id)
        }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: key)
    }
}
