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

    @discardableResult
    func toggle(_ station: BikeStation) -> Bool {
        let wasAdded = !favoriteIDs.contains(station.id)
        if wasAdded {
            favoriteIDs.insert(station.id)
        } else {
            favoriteIDs.remove(station.id)
        }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: key)
        return wasAdded
    }
}
