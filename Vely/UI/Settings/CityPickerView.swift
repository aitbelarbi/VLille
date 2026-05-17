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
        guard !searchText.isEmpty else { return City.all }
        return City.all.filter {
            $0.localizedName.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.serviceName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredCities) { city in
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
        .searchable(text: $searchText, prompt: LocalizedStringKey("onboarding_search_placeholder"))
        .navigationTitle(LocalizedStringKey("settings_section_city"))
        .navigationBarTitleDisplayMode(.large)
    }
}
