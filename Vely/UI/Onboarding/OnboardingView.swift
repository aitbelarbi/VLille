import SwiftUI
import CoreLocation
import MapKit

struct OnboardingView: View {
    @Environment(CityStore.self) var cityStore
    @Environment(ProfileStore.self) var profileStore
    @Environment(LocationManager.self) var locationManager

    @State private var step: Step = .profile
    @State private var selectedProfile: UserProfile = .bikesharing
    @State private var selectedCity: City? = nil
    @State private var searchText = ""
    @State private var selectedCountryCode: String? = nil
    @State private var onboardingViewModel = OnboardingViewModel()

    enum Step { case profile, location, locating, city }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()

            Group {
                switch step {
                case .profile:
                    profileStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .location:
                    locationStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .locating:
                    locatingView
                        .transition(.opacity)
                case .city:
                    cityStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            guard step == .location || step == .locating else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                step = .locating
                Task { await detectAndComplete() }
            case .denied, .restricted:
                step = .city
            default:
                break
            }
        }
    }

    // MARK: - Step 1: Profile

    private var profileStep: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                icon: "bicycle.circle.fill",
                titleKey: "onboarding_title",
                subtitleKey: "onboarding_profile_subtitle"
            )

            Spacer()

            VStack(spacing: 16) {
                ProfileOptionCard(
                    icon: "network",
                    titleKey: "profile_bikesharing_title",
                    descKey: "profile_bikesharing_desc",
                    isSelected: selectedProfile == .bikesharing
                ) {
                    withAnimation(.spring(response: 0.3)) { selectedProfile = .bikesharing }
                }

                ProfileOptionCard(
                    icon: "figure.outdoor.cycle",
                    titleKey: "profile_cyclist_title",
                    descKey: "profile_cyclist_desc",
                    isSelected: selectedProfile == .cyclist
                ) {
                    withAnimation(.spring(response: 0.3)) { selectedProfile = .cyclist }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Color.clear.frame(height: 80)
        }
        .safeAreaInset(edge: .bottom) {
            ctaButton(labelKey: "onboarding_next") {
                withAnimation(.spring(response: 0.4)) { step = .location }
            }
        }
    }

    // MARK: - Step 2: Location permission

    private var locationStep: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                icon: "location.circle.fill",
                titleKey: "onboarding_location_title",
                subtitleKey: "onboarding_location_desc",
                backAction: { step = .profile }
            )

            VStack(spacing: 0) {
                LocationBenefitRow(icon: "mappin.and.ellipse", color: .indigo,   key: "location_benefit_city")
                Divider().padding(.leading, 56)
                LocationBenefitRow(icon: "bicycle",            color: .green,    key: "location_benefit_stations")
                Divider().padding(.leading, 56)
                LocationBenefitRow(icon: "location.fill",      color: .blue,     key: "location_benefit_center")
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()

            Button {
                switch locationManager.authorizationStatus {
                case .denied, .restricted:
                    withAnimation(.spring(response: 0.4)) { step = .city }
                default:
                    locationManager.requestLocationPermission()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                    Text("onboarding_location_cta").font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.indigo, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .shadow(color: .indigo.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Step 3: Locating spinner

    private var locatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.indigo)
            Text("onboarding_detecting_city")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Step 4: City selection (fallback)

    private var cityStep: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                icon: "mappin.circle.fill",
                titleKey: "onboarding_title",
                subtitleKey: "onboarding_subtitle",
                backAction: { step = .location }
            )

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("onboarding_search_placeholder", text: $searchText)
                    .autocorrectionDisabled()
                if onboardingViewModel.isSearching {
                    ProgressView().scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if searchText.isEmpty {
                        countryChips
                    }
                    if !filteredCities.isEmpty {
                        cityList
                    } else if !onboardingViewModel.results.isEmpty {
                        mapKitCityList
                    }
                    Color.clear.frame(height: 80)
                }
                .padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            ctaButton(labelKey: "onboarding_confirm", disabled: selectedCity == nil) {
                guard let city = selectedCity else { return }
                profileStore.setProfile(selectedProfile)
                cityStore.selectCity(city)
                withAnimation { cityStore.completeOnboarding() }
            }
        }
        .onChange(of: searchText) { _, newValue in
            selectedCity = nil
            onboardingViewModel.search(newValue, fallbackFrom: filteredCities)
        }
    }

    private var mapKitCityList: some View {
        LazyVStack(spacing: 0) {
            ForEach(onboardingViewModel.results, id: \.self) { item in
                let cityName = item.placemark.locality ?? item.placemark.administrativeArea ?? item.name ?? ""
                let countryCode = item.placemark.isoCountryCode ?? ""
                let isSelected = selectedCity?.name == cityName
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCity = City.unsupported(from: item.placemark)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(countryCode.flagEmoji).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cityName).font(.headline).foregroundStyle(.primary)
                            if let country = item.placemark.country {
                                Text(country).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? .indigo : Color.secondary.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isSelected ? Color.indigo.opacity(0.06) : Color.clear)
                    .contentShape(Rectangle())
                    .overlay(alignment: .bottom) { Divider().padding(.leading, 56) }
                }
                .buttonStyle(.plain)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    // MARK: - Shared subviews

    @ViewBuilder
    private func onboardingHeader(
        icon: String,
        titleKey: LocalizedStringKey,
        subtitleKey: LocalizedStringKey,
        backAction: (() -> Void)? = nil
    ) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 52))
                    .foregroundStyle(.indigo)
                    .padding(.top, backAction != nil ? 72 : 40)
                Text(titleKey)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(subtitleKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)

            if let backAction {
                Button(action: backAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.subheadline.weight(.semibold))
                        Text("common_back").font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.indigo)
                }
                .padding(.top, 56)
                .padding(.leading, 16)
            }
        }
        .background(
            LinearGradient(colors: [Color.indigo.opacity(0.10), Color.clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }

    @ViewBuilder
    private func ctaButton(labelKey: LocalizedStringKey, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(labelKey)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(disabled ? Color.secondary.opacity(0.3) : .indigo, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .shadow(color: .indigo.opacity(disabled ? 0 : 0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(disabled)
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

    private var countryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedCountryCode = nil }
                } label: {
                    Text("🌍")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(selectedCountryCode == nil ? AnyShapeStyle(Color.indigo) : AnyShapeStyle(.regularMaterial), in: Capsule())
                        .foregroundStyle(selectedCountryCode == nil ? .white : .primary)
                }
                .buttonStyle(.plain)

                ForEach(availableCountries, id: \.code) { country in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCountryCode = selectedCountryCode == country.code ? nil : country.code
                        }
                    } label: {
                        Text(country.code.flagEmoji)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(
                                selectedCountryCode == country.code ? AnyShapeStyle(Color.indigo) : AnyShapeStyle(.regularMaterial),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedCountryCode == country.code ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var cityList: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredCities) { city in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedCity = city }
                } label: {
                    HStack(spacing: 12) {
                        Text(city.countryFlag).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.localizedName).font(.headline).foregroundStyle(.primary)
                            Text(city.serviceName).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: selectedCity?.id == city.id ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selectedCity?.id == city.id ? .indigo : Color.secondary.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(selectedCity?.id == city.id ? Color.indigo.opacity(0.06) : Color.clear)
                    .contentShape(Rectangle())
                    .overlay(alignment: .bottom) { Divider().padding(.leading, 56) }
                }
                .buttonStyle(.plain)
            }

            if cityStore.isLoadingCities {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Chargement des villes...")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    // MARK: - Computed

    private var availableCountries: [(code: String, name: String, count: Int)] {
        let grouped = Dictionary(grouping: cityStore.cities, by: \.countryCode)
        return grouped.map { (code: $0.key, name: Locale.current.localizedString(forRegionCode: $0.key) ?? $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var filteredCities: [City] {
        var base = cityStore.cities
        if let country = selectedCountryCode { base = base.filter { $0.countryCode == country } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            base = base.filter {
                $0.name.lowercased().contains(q) ||
                $0.localizedName.lowercased().contains(q) ||
                $0.serviceName.lowercased().contains(q) ||
                $0.countryName.lowercased().contains(q)
            }
        }
        return base
    }

    // MARK: - Location helpers

    private func detectAndComplete() async {
        let start = Date()
        while locationManager.userLocation == nil && Date().timeIntervalSince(start) < 6 {
            try? await Task.sleep(for: .milliseconds(300))
        }
        guard let location = locationManager.userLocation else {
            await MainActor.run {
                withAnimation(.spring(response: 0.4)) { step = .city }
            }
            return
        }
        let nearest = cityStore.cities.min {
            location.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <
            location.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
        }
        guard let nearest,
              location.distance(from: CLLocation(latitude: nearest.latitude, longitude: nearest.longitude)) < 100_000
        else {
            await MainActor.run {
                withAnimation(.spring(response: 0.4)) { step = .city }
            }
            return
        }
        await MainActor.run {
            profileStore.setProfile(selectedProfile)
            cityStore.selectCity(nearest)
            withAnimation { cityStore.completeOnboarding() }
        }
    }
}

// MARK: - LocationBenefitRow

private struct LocationBenefitRow: View {
    let icon: String
    let color: Color
    let key: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(key)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - ProfileOptionCard

private struct ProfileOptionCard: View {
    let icon: String
    let titleKey: LocalizedStringKey
    let descKey: LocalizedStringKey
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.indigo.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : .indigo)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(titleKey)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    Text(descKey)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : Color.secondary.opacity(0.4))
            }
            .padding(16)
            .background(
                isSelected ? AnyShapeStyle(Color.indigo) : AnyShapeStyle(.regularMaterial),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.indigo.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    OnboardingView()
        .environment(CityStore())
        .environment(ProfileStore())
        .environment(LocationManager())
}
