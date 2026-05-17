import SwiftUI
import WeatherKit

struct WeatherDetailView: View {
    let weather: WeatherManager

    var body: some View {
        NavigationStack {
            Group {
                if let current = weather.current {
                    List {
                        currentSection(current)
                        hourlySection
                        attributionSection
                    }
                } else {
                    ContentUnavailableView(
                        "weather_unavailable",
                        systemImage: "cloud.slash"
                    )
                }
            }
            .navigationTitle("weather_hourly_forecast")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private func currentSection(_ current: CurrentWeather) -> some View {
        Section {
            HStack {
                Image(systemName: current.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 40))
                    .frame(width: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text(current.temperature.formatted(.measurement(width: .abbreviated, usage: .weather)))
                        .font(.title.bold())
                    Text(current.condition.description)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)

            LabeledContent {
                Text(current.apparentTemperature.formatted(.measurement(width: .abbreviated, usage: .weather)))
            } label: {
                Label("weather_feels_like", systemImage: "thermometer.medium")
            }

            LabeledContent {
                Text(current.wind.speed.formatted(.measurement(width: .abbreviated)))
            } label: {
                Label("weather_wind", systemImage: "wind")
            }
        }
    }

    private var hourlySection: some View {
        Section("weather_hourly_forecast") {
            ForEach(weather.hourly, id: \.date) { hour in
                HStack {
                    Text(hour.date, format: .dateTime.hour())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    Image(systemName: hour.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .frame(width: 28)
                    Text(hour.temperature.formatted(.measurement(width: .abbreviated, usage: .weather)))
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if hour.precipitationChance > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(.blue)
                                .font(.caption2)
                            Text(hour.precipitationChance, format: .percent.precision(.fractionLength(0)))
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
    }

    private var attributionSection: some View {
        Section {
            if let attribution = weather.attribution {
                Link(destination: attribution.legalPageURL) {
                    HStack(spacing: 6) {
                        AsyncImage(url: attribution.combinedMarkLightURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Text("weather_data_source")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 14)
                    }
                }
            }
        }
    }
}
