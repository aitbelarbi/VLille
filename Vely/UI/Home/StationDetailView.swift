//
//  StationDetailView.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 16/05/2026.
//

import MapKit
import SwiftUI

struct StationDetailView: View {
    let station: BikeStation
    let isCalculatingRoute: Bool
    let onRouteRequest: (() -> Void)?
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(LocationManager.self) var locationManager
    @Environment(RatingManager.self) var ratingManager
    @Environment(\.openURL) private var openURL
    @State private var showMapAppPicker = false
    @State private var showLocationDeniedAlert = false

    init(station: BikeStation, isCalculatingRoute: Bool = false, onRouteRequest: (() -> Void)? = nil) {
        self.station = station
        self.isCalculatingRoute = isCalculatingRoute
        self.onRouteRequest = onRouteRequest
    }

    var statusColor: Color {
        guard station.isOperational else { return .red }
        return station.bikesAvailable > 0 ? .green : .orange
    }

    var availableMapApps: [(name: String, action: () -> Void)] {
        var apps: [(String, () -> Void)] = [("Apple Maps", openInAppleMaps)]
        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
            apps.append(("Google Maps", openInGoogleMaps))
        }
        if UIApplication.shared.canOpenURL(URL(string: "waze://")!) {
            apps.append(("Waze", openInWaze))
        }
        if UIApplication.shared.canOpenURL(URL(string: "citymapper://")!) {
            apps.append(("Citymapper", openInCitymapper))
        }
        return apps
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .font(.title2.bold())
                    Text(station.address)
                        .foregroundStyle(.secondary)
                    if let district = station.district {
                        Text(district)
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
                Spacer()
                Button {
                    if favoritesStore.toggle(station) {
                        ratingManager.recordFavoriteAdded()
                    }
                } label: {
                    Image(systemName: favoritesStore.isFavorite(station) ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                }
            }

            HStack(spacing: 0) {
                StatBadge(value: station.bikesAvailable, label: "station_bikes", icon: "bicycle", color: .green)
                Divider().frame(height: 50)
                StatBadge(value: station.docksAvailable, label: "station_spots", icon: "parkingsign", color: .blue)
            }
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text(station.isOperational ? LocalizedStringKey("station_status_operational") : LocalizedStringKey("station_status_closed"))
                    .font(.footnote)
                Spacer()
                if let type = station.stationType {
                    Text(type)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if locationManager.userLocation != nil, let onRouteRequest {
                HStack(spacing: 12) {
                    Button(action: onRouteRequest) {
                        HStack {
                            if isCalculatingRoute {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "figure.walk")
                            }
                            Text("routing_walking")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isCalculatingRoute)

                    Button { showMapAppPicker = true } label: {
                        HStack {
                            Image(systemName: "bicycle")
                            Text("routing_cycling")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .confirmationDialog("action_open_with", isPresented: $showMapAppPicker, titleVisibility: .visible) {
                        ForEach(availableMapApps, id: \.name) { app in
                            Button(app.name) { app.action() }
                        }
                    }
                }
            } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted, onRouteRequest != nil {
                Button { showLocationDeniedAlert = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("location_denied_cta")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.secondary.opacity(0.15))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .alert("location_denied_alert_title", isPresented: $showLocationDeniedAlert) {
                    Button("location_denied_open_settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("common_cancel", role: .cancel) {}
                } message: {
                    Text("location_denied_alert_message")
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openInAppleMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)))
        item.name = station.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeCycling])
    }

    private func openInGoogleMaps() {
        openURL(URL(string: "comgooglemaps://?saddr=&daddr=\(station.latitude),\(station.longitude)&directionsmode=bicycling")!)
    }

    private func openInWaze() {
        openURL(URL(string: "waze://?ll=\(station.latitude),\(station.longitude)&navigate=yes")!)
    }

    private func openInCitymapper() {
        let name = station.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        openURL(URL(string: "citymapper://directions?endcoord=\(station.latitude),\(station.longitude)&endname=\(name)")!)
    }
}

struct StatBadge: View {
    let value: Int
    let label: LocalizedStringKey
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.title.bold())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            Spacer()
        }
    }
}
