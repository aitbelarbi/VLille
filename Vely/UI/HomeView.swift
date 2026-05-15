import SwiftUI
import MapKit

struct MapView: View {
    var viewModel: HomeViewModel
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(LocationManager.self) var locationManager
    @Binding var cameraPosition: MapCameraPosition
    @State private var selectedStation: VLilleStation?
    @State private var currentRoute: MKRoute?
    @State private var isCalculatingRoute = false
    @State private var hascenteredOnUser = false
    @State private var visibleRegion: MKCoordinateRegion?
    
    enum MapType: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case satellite = "Satellite"
        case hybride = "Hybride"
        case `3d` = "3D Réaliste"
        
        var localizedTitle: LocalizedStringKey { LocalizedStringKey(rawValue) }

        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .standard: return "map"
            case .satellite: return "globe.europe.africa"
            case .hybride: return "square.3.layers.3d.bottom.filled"
            case .`3d`: return "building.2"
            }
        }
    }
    
    // 2. AJOUT : L'état pour mémoriser le choix de l'utilisateur
    @State private var selectedMapType: MapType = .standard
    @State private var showOnlyAvailable = false
    @State private var showRefreshToast = false

    var displayedStations: [VLilleStation] {
        showOnlyAvailable ? viewModel.stations.filter { $0.nbVelosDispo > 0 } : viewModel.stations
    }

    var displayedClusters: [StationCluster] {
        let span = visibleRegion?.span ?? MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        guard span.latitudeDelta > 0.015 else {
            return displayedStations.map {
                StationCluster(id: "s_\($0.id)", coordinate: CLLocationCoordinate2D(latitude: $0.y, longitude: $0.x), stations: [$0])
            }
        }
        let cellSize = span.latitudeDelta / 6
        var groups: [String: [VLilleStation]] = [:]
        for station in displayedStations {
            let row = Int(floor(station.y / cellSize))
            let col = Int(floor(station.x / cellSize))
            groups["\(row)_\(col)", default: []].append(station)
        }
        return groups.map { key, group in
            let avgLat = group.reduce(0.0) { $0 + $1.y } / Double(group.count)
            let avgLon = group.reduce(0.0) { $0 + $1.x } / Double(group.count)
            return StationCluster(id: key, coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon), stations: group)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    ForEach(displayedClusters) { cluster in
                        Annotation("", coordinate: cluster.coordinate) {
                            ClusterMarkerView(cluster: cluster, favoritesStore: favoritesStore) {
                                handleClusterTap(cluster)
                            }
                        }
                    }

                    if let route = currentRoute {
                        MapPolyline(route.polyline)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .mapStyle(currentMapStyle)
                .onMapCameraChange { context in
                    visibleRegion = context.region
                }

                // Top bar : filtre
                VStack {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showOnlyAvailable.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showOnlyAvailable ? "bicycle.circle.fill" : "bicycle.circle")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(showOnlyAvailable ? LocalizedStringKey("Vélos disponibles") : LocalizedStringKey("Toutes les stations"))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                showOnlyAvailable
                                    ? AnyShapeStyle(Color.indigo)
                                    : AnyShapeStyle(.regularMaterial),
                                in: Capsule()
                            )
                            .foregroundStyle(showOnlyAvailable ? .white : .primary)
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .scaleEffect(showOnlyAvailable ? 1.03 : 1.0)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                    // Toast refresh
                    if showRefreshToast {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundStyle(.green)
                            Text("Données mises à jour", comment: "")
                                .font(.footnote.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()
                }
                .onChange(of: viewModel.lastUpdated) {
                    guard viewModel.lastUpdated != nil else { return }
                    withAnimation(.easeOut) { showRefreshToast = true }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation(.easeIn) { showRefreshToast = false }
                    }
                }

                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Menu {
                            Picker("Type de carte", selection: $selectedMapType) {
                                ForEach(MapType.allCases) { type in
                                    Label(type.localizedTitle, systemImage: type.icon).tag(type)
                                }
                            }
                        } label: {
                            Image(systemName: "square.3.layers.3d")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 40, height: 40)
                        }
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        // Tes boutons existants (Centrage)
                        Button { centerOnUser() } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(locationManager.userLocation != nil ? .blue : .secondary)
                                .frame(width: 40, height: 40)
                        }
                        .fixedSize()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .disabled(locationManager.userLocation == nil)

                        // Zoom +/-
                        VStack(spacing: 0) {
                            Button { zoom(in: true) } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 40, height: 40)
                            }
                            Divider().frame(width: 40)
                            Button { zoom(in: false) } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 40, height: 40)
                            }
                        }
                        .fixedSize()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                // ... Reste de tes ProgressView et messages d'erreur inchangés ...
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .foregroundStyle(.red)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding()
                    }
                }
            }
            .navigationTitle("Stations vélo")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedStation) { station in
                StationDetailView(station: station, isCalculatingRoute: isCalculatingRoute) {
                    selectedStation = nil
                    calculateRoute(to: station)
                }
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                locationManager.requestLocationPermission()
            }
            .onChange(of: locationManager.userLocation) { _, location in
                guard let location, !hascenteredOnUser else { return }
                hascenteredOnUser = true
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }

    private func handleClusterTap(_ cluster: StationCluster) {
        if cluster.stations.count == 1 {
            selectedStation = cluster.stations[0]
        } else {
            let lats = cluster.stations.map { $0.y }
            let lons = cluster.stations.map { $0.x }
            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLon = lons.min(), let maxLon = lons.max() else { return }
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
                    span: MKCoordinateSpan(
                        latitudeDelta: max((maxLat - minLat) * 2.5, 0.005),
                        longitudeDelta: max((maxLon - minLon) * 2.5, 0.005)
                    )
                ))
            }
        }
    }

    private func calculateRoute(to station: VLilleStation) {
        guard let userLocation = locationManager.userLocation else { return }
        isCalculatingRoute = true
        currentRoute = nil

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: station.y, longitude: station.x)
        ))
        request.transportType = .walking

        Task {
            let directions = MKDirections(request: request)
            if let response = try? await directions.calculate() {
                await MainActor.run {
                    currentRoute = response.routes.first
                    isCalculatingRoute = false
                    if let route = currentRoute {
                        var region = MKCoordinateRegion(route.polyline.boundingMapRect)
                        region.span.latitudeDelta *= 1.4
                        region.span.longitudeDelta *= 1.4
                        cameraPosition = .region(region)
                    }
                }
            } else {
                await MainActor.run { isCalculatingRoute = false }
            }
        }
    }

    private func centerOnUser() {
        guard let location = locationManager.userLocation else { return }
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    private func zoom(in zoomIn: Bool) {
        // visibleRegion est mis à jour par onMapCameraChange à chaque mouvement,
        // donc fonctionne même après un pan/pinch manuel
        guard let region = visibleRegion ?? cameraPosition.region else { return }
        let factor = zoomIn ? 0.5 : 2.0
        cameraPosition = .region(MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: max(0.001, min(region.span.latitudeDelta * factor, 180)),
                longitudeDelta: max(0.001, min(region.span.longitudeDelta * factor, 180))
            )
        ))
    }
    
    private var currentMapStyle: MapStyle {
        switch selectedMapType {
        case .standard:
            return .standard(elevation: .flat, showsTraffic: false)
        case .satellite:
            return .imagery(elevation: .flat)
        case .hybride:
            return .hybrid(elevation: .flat, showsTraffic: false)
        case .`3d`:
            return .standard(elevation: .realistic, showsTraffic: false)
        }
    }
}


// MARK: - Clustering

struct StationCluster: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let stations: [VLilleStation]

    var isCluster: Bool { stations.count > 1 }
    var totalBikes: Int { stations.reduce(0) { $0 + $1.nbVelosDispo } }

    var markerColor: Color {
        guard stations.allSatisfy({ $0.etat == "EN SERVICE" }) == false
                ? stations.contains(where: { $0.etat == "EN SERVICE" })
                : true
        else { return .red }
        return totalBikes > 0 ? .green : .orange
    }
}

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
                        Text("\(cluster.stations.count) stations")
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

// MARK: - Marqueur sur la carte

struct StationMarkerView: View {
    let station: VLilleStation
    let isFavorite: Bool

    var markerColor: Color {
        guard station.etat == "EN SERVICE" else { return .red }
        return station.nbVelosDispo > 0 ? .green : .orange
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: 32, height: 32)
                    .shadow(radius: 2)
                Text("\(station.nbVelosDispo)")
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

// MARK: - Fiche détail station

struct StationDetailView: View {
    let station: VLilleStation
    let isCalculatingRoute: Bool
    let onRouteRequest: (() -> Void)?
    @Environment(FavoritesStore.self) var favoritesStore
    @Environment(LocationManager.self) var locationManager
    @Environment(\.openURL) private var openURL
    @State private var showMapAppPicker = false

    init(station: VLilleStation, isCalculatingRoute: Bool = false, onRouteRequest: (() -> Void)? = nil) {
        self.station = station
        self.isCalculatingRoute = isCalculatingRoute
        self.onRouteRequest = onRouteRequest
    }

    var statusColor: Color {
        guard station.etat == "EN SERVICE" else { return .red }
        return station.etatConnexion == "CONNECTÉ" ? .green : .orange
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
                    Text(station.nom)
                        .font(.title2.bold())
                    Text(station.adresse)
                        .foregroundStyle(.secondary)
                    if let commune = station.commune {
                        Text(commune)
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
                Spacer()
                Button {
                    favoritesStore.toggle(station)
                } label: {
                    Image(systemName: favoritesStore.isFavorite(station) ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                }
            }

            HStack(spacing: 0) {
                StatBadge(value: station.nbVelosDispo, label: "Vélos", icon: "bicycle", color: .green)
                Divider().frame(height: 50)
                StatBadge(value: station.nbPlacesDispo, label: "Places", icon: "parkingsign", color: .blue)
            }
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text(station.etat)
                    .font(.footnote)
                Spacer()
                Text(station.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                            Text("À pied")
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
                            Text("À vélo")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .confirmationDialog("Ouvrir avec…", isPresented: $showMapAppPicker, titleVisibility: .visible) {
                        ForEach(availableMapApps, id: \.name) { app in
                            Button(app.name) { app.action() }
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openInAppleMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: station.y, longitude: station.x)))
        item.name = station.nom
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeCycling])
    }

    private func openInGoogleMaps() {
        openURL(URL(string: "comgooglemaps://?saddr=&daddr=\(station.y),\(station.x)&directionsmode=bicycling")!)
    }

    private func openInWaze() {
        openURL(URL(string: "waze://?ll=\(station.y),\(station.x)&navigate=yes")!)
    }

    private func openInCitymapper() {
        let name = station.nom.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        openURL(URL(string: "citymapper://directions?endcoord=\(station.y),\(station.x)&endname=\(name)")!)
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

#Preview {
    MainTabView()
        .environment(FavoritesStore())
        .environment(LocationManager())
}
