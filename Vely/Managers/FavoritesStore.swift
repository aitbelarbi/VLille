//
//  FavoritesStore.swift
//  Vlille
//

import Foundation
import Observation

@Observable
class FavoritesStore {
    private(set) var favoriteIDs: Set<Int> = []
    @ObservationIgnored private let key = "favorite_station_ids"

    init() {
        let saved = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        favoriteIDs = Set(saved)
    }

    func isFavorite(_ station: VLilleStation) -> Bool {
        favoriteIDs.contains(station.id)
    }

    func toggle(_ station: VLilleStation) {
        if favoriteIDs.contains(station.id) {
            favoriteIDs.remove(station.id)
        } else {
            favoriteIDs.insert(station.id)
        }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: key)
    }
}
