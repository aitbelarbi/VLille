import SwiftUI
import MapKit

// MARK: - Tab principale

struct MainTabView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab = 0
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.6292, longitude: 3.0573),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Carte", systemImage: "map", value: 0) {
                MapView(viewModel: viewModel, cameraPosition: $cameraPosition)
            }
            if selectedTab != 2 {
                Tab("Favoris", systemImage: "star", value: 1) {
                    FavoritesView(viewModel: viewModel, selectedTab: $selectedTab, cameraPosition: $cameraPosition)
                }
            }

            Tab("Recherche", systemImage: "magnifyingglass", value: 2, role: .search) {                SearchView(viewModel: viewModel, selectedTab: $selectedTab, cameraPosition: $cameraPosition)
            }
        }
        .onAppear {
            viewModel.fetchStations()
        }
    }
}

// MARK: - Vue Carte

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

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, selection: $selectedStation) {
                    // Position utilisateur
                    UserAnnotation()

                    ForEach(viewModel.stations) { station in
                        Annotation(station.nom, coordinate: CLLocationCoordinate2D(latitude: station.y, longitude: station.x)) {
                            StationMarkerView(station: station, isFavorite: favoritesStore.isFavorite(station))
                        }
                        .tag(station)
                    }

                    // Tracé de l'itinéraire
                    if let route = currentRoute {
                        MapPolyline(route.polyline)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .onMapCameraChange { context in
                    visibleRegion = context.region
                }

                // Boutons zoom + centrage
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        // Centrer sur l'utilisateur
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
            .navigationTitle("Stations VLille")
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
}

// MARK: - Vue Favoris

struct FavoritesView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var favoritesStore: FavoritesStore
    @Binding var selectedTab: Int
    @Binding var cameraPosition: MapCameraPosition
    @State private var selectedStation: VLilleStation?

    var favoriteStations: [VLilleStation] {
        viewModel.stations.filter { favoritesStore.isFavorite($0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteStations.isEmpty {
                    ContentUnavailableView(
                        "Aucun favori",
                        systemImage: "star.slash",
                        description: Text("Ajoutez des stations en favoris depuis la carte.")
                    )
                } else {
                    List(favoriteStations) { station in
                        Button {
                            goToStation(station)
                        } label: {
                            StationRowView(station: station)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Favoris")
            .sheet(item: $selectedStation) { station in
                StationDetailView(station: station)
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func goToStation(_ station: VLilleStation) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: station.y, longitude: station.x),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        )
        selectedTab = 0
    }
}

// MARK: - Ligne station (liste favoris)

struct StationRowView: View {
    let station: VLilleStation

    var statusColor: Color {
        guard station.etat == "EN SERVICE" else { return .red }
        return station.nbVelosDispo > 0 ? .green : .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 40, height: 40)
                Text("\(station.nbVelosDispo)")
                    .font(.callout.bold())
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(station.nom)
                    .font(.headline)
                Text(station.adresse)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Label("\(station.nbVelosDispo)", systemImage: "bicycle")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                Label("\(station.nbPlacesDispo)", systemImage: "parkingsign")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
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
                    .font(.system(size: 10))
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
