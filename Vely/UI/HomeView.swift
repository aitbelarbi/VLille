import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var favoritesStore: FavoritesStore
    @EnvironmentObject var locationManager: LocationManager
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

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, selection: $selectedStation) {
                    UserAnnotation()

                    ForEach(viewModel.stations) { station in
                        Annotation(station.nom, coordinate: CLLocationCoordinate2D(latitude: station.y, longitude: station.x)) {
                            StationMarkerView(station: station, isFavorite: favoritesStore.isFavorite(station))
                        }
                        .tag(station)
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

                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        
                        // 4. AJOUT : Le bouton de sélection du type de carte
                        Menu {
                            Picker("Type de carte", selection: $selectedMapType) {
                                ForEach(MapType.allCases) { type in
                                    Label(type.rawValue, systemImage: type.icon).tag(type)
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
    @EnvironmentObject var favoritesStore: FavoritesStore
    @EnvironmentObject var locationManager: LocationManager
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
    let label: String
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
        .environmentObject(FavoritesStore())
        .environmentObject(LocationManager())
}
