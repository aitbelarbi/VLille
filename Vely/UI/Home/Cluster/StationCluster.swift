//
//  StationCluster.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 17/05/2026.
//

import MapKit
import SwiftUI

struct StationCluster: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let stations: [BikeStation]

    var isCluster: Bool { stations.count > 1 }
    var totalBikes: Int { stations.reduce(0) { $0 + $1.bikesAvailable } }

    var markerColor: Color {
        let hasOperational = stations.contains { $0.isOperational }
        guard hasOperational else { return .red }
        return totalBikes > 0 ? .green : .orange
    }
}
