import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Environment(CityStore.self) var cityStore
    @State private var selectedCity: City = .lille
    @State private var searchText: String = ""

    private let featuredIds = ["paris", "lyon", "toulouse", "nantes", "bruxelles", "dublin"]

    private var filteredCities: [City] {
        guard !searchText.isEmpty else { return City.all }
        let q = searchText.lowercased()
        return City.all.filter {
            $0.name.lowercased().contains(q) || $0.serviceName.lowercased().contains(q)
        }
    }

    private var featuredCities: [City] {
        featuredIds.compactMap { id in City.all.first { $0.id == id } }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header — gradient en background, hauteur définie par le contenu
                VStack(spacing: 10) {
                    Image(systemName: "bicycle.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.indigo)
                        .padding(.top, 56)
                    Text("onboarding_title")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("onboarding_subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.10), Color.clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                )

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("onboarding_search_placeholder", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Popular chips — only when not searching
                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Populaires")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(featuredCities) { city in
                                            Button {
                                                withAnimation(.spring(response: 0.3)) { selectedCity = city }
                                            } label: {
                                                Text("\(city.countryFlag) \(city.name)")
                                                    .font(.subheadline.weight(.medium))
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 7)
                                                    .background(
                                                        selectedCity.id == city.id
                                                            ? AnyShapeStyle(Color.indigo)
                                                            : AnyShapeStyle(.regularMaterial),
                                                        in: Capsule()
                                                    )
                                                    .foregroundStyle(selectedCity.id == city.id ? .white : .primary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        // City list
                        LazyVStack(spacing: 0) {
                            ForEach(filteredCities) { city in
                                Button {
                                    withAnimation(.spring(response: 0.3)) { selectedCity = city }
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(city.countryFlag)
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(city.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text(city.serviceName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: selectedCity.id == city.id ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(selectedCity.id == city.id ? .indigo : Color.secondary.opacity(0.4))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedCity.id == city.id
                                            ? Color.indigo.opacity(0.06)
                                            : Color.clear
                                    )
                                    .contentShape(Rectangle())
                                    .overlay(alignment: .bottom) {
                                        Divider().padding(.leading, 56)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(.background, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)

                        // Bottom padding so list clears the CTA button
                        Color.clear.frame(height: 80)
                    }
                    .padding(.top, 8)
                }
            }

            // Fixed CTA button
            Button {
                cityStore.selectCity(selectedCity)
                withAnimation { cityStore.completeOnboarding() }
            } label: {
                Text("onboarding_confirm")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.indigo, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .shadow(color: .indigo.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color(.systemGroupedBackground).opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .task { await autoSelectNearestCity() }
    }

    private func autoSelectNearestCity() async {
        let manager = CLLocationManager()
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways,
              let location = manager.location else { return }
        let nearest = City.all.min {
            location.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <
            location.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
        }
        guard let nearest else { return }
        let distance = location.distance(from: CLLocation(latitude: nearest.latitude, longitude: nearest.longitude))
        guard distance < 100_000 else { return }
        withAnimation(.spring(response: 0.4)) { selectedCity = nearest }
    }
}

#Preview {
    OnboardingView()
        .environment(CityStore())
}

