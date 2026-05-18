//
//  StationMarkerView.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 17/05/2026.
//

import SwiftUI

struct StationMarkerView: View {
    let station: BikeStation
    let isFavorite: Bool

    var markerColor: Color {
        guard station.isOperational else { return .red }
        return station.bikesAvailable > 0 ? .green : .orange
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 2) {
                Image(systemName: "bicycle")
                    .font(.system(size: 10, weight: .bold))
                Text("\(station.bikesAvailable)/\(station.docksAvailable)")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .foregroundStyle(.white)
            .background(markerColor.opacity(0.80))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
            
            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
                    .offset(x: 3, y: -3)
            }
        }
    }
}
