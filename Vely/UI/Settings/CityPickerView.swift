//
//  CityPickerView.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 17/05/2026.
//

import SwiftUI

struct CityPickerView: View {
    @Environment(CityStore.self) var cityStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredCities: [City] {
        guard !searchText.isEmpty else { return cityStore.cities }
        return cityStore.cities.filter {
            $0.localizedName.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.serviceName.localizedCaseInsensitiveContains(searchText) ||
            $0.countryName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedCities: [(country: String, cities: [City])] {
        let grouped = Dictionary(grouping: filteredCities, by: \.countryCode)
        return grouped.map { (
            country: Locale.current.localizedString(forRegionCode: $0.key) ?? $0.key,
            cities: $0.value.sorted { $0.name < $1.name }
        )}
        .sorted { $0.country < $1.country }
    }

    var body: some View {
        List {
            ForEach(groupedCities, id: \.country) { group in
                Section(group.country) {
                    ForEach(group.cities) { city in
                        Button {
                            cityStore.selectCity(city)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(city.countryFlag)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.localizedName)
                                        .foregroundStyle(.primary)
                                    Text(city.serviceName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if cityStore.selectedCity.id == city.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.indigo)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
            }

            if cityStore.isLoadingCities {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Chargement des villes...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $searchText, prompt: LocalizedStringKey("onboarding_search_placeholder"))
        .navigationTitle(LocalizedStringKey("settings_section_city"))
        .navigationBarTitleDisplayMode(.large)
    }
}
