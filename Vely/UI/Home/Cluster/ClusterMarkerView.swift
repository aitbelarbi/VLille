//
//  ClusterMarkerView.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 17/05/2026.
//

import SwiftUI

struct ClusterMarkerView: View {
    let cluster: StationCluster
    let favoritesStore: FavoritesStore
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            if cluster.isCluster {
                ZStack {
                    Circle()
                        .fill(cluster.markerColor)
                        .frame(width: 44, height: 44)
                        .shadow(radius: 3)
                    VStack(spacing: 1) {
                        Text("\(cluster.totalBikes)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        Text(String(format: String(localized: "cluster_stations_count"), Int64(cluster.stations.count)))
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            } else {
                let station = cluster.stations[0]
                StationMarkerView(station: station, isFavorite: favoritesStore.isFavorite(station))
            }
        }
        .buttonStyle(.plain)
    }
}
