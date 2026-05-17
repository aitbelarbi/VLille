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
                        .frame(width: 48, height: 48)
                        .shadow(radius: 3)
                    VStack(spacing: 1) {
                        HStack(spacing: 2) {
                            Image(systemName: "bicycle")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(cluster.totalBikes)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        HStack(spacing: 2) {
                            Image(systemName: "parkingsign")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(cluster.totalDocks)")
                                .font(.system(size: 12, weight: .bold))
                        }
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
