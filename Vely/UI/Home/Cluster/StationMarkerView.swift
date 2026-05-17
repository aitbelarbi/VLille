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
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: 32, height: 32)
                    .shadow(radius: 2)
                Text("\(station.bikesAvailable)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
                    .offset(x: 4, y: -4)
            }
        }
    }
}
