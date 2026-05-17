import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Environment(CityStore.self) var cityStore
    @State private var selectedCity: City = .lille

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "bicycle.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.indigo)

                    Text("onboarding_title")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("onboarding_subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    ForEach(City.all) { city in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCity = city
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(selectedCity.id == city.id ? .white : .indigo)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.name)
                                        .font(.headline)
                                    Text(city.provider.dataCredit)
                                        .font(.caption)
                                        .opacity(0.8)
                                }

                                Spacer()

                                if selectedCity.id == city.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                }
                            }
                            .padding(16)
                            .background(
                                selectedCity.id == city.id ? AnyShapeStyle(Color.indigo) : AnyShapeStyle(.regularMaterial),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(selectedCity.id == city.id ? .white : .primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.indigo.opacity(selectedCity.id == city.id ? 0 : 0.3), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    cityStore.selectCity(selectedCity)
                    withAnimation { cityStore.completeOnboarding() }
                } label: {
                    Text("onboarding_confirm")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.indigo, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .task {
            await autoSelectNearestCity()
        }
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

        // Only auto-select if the user is reasonably close (within 100km)
        let distance = location.distance(from: CLLocation(latitude: nearest.latitude, longitude: nearest.longitude))
        guard distance < 100_000 else { return }

        withAnimation(.spring(response: 0.4)) {
            selectedCity = nearest
        }
    }
}

#Preview {
    OnboardingView()
        .environment(CityStore())
}
