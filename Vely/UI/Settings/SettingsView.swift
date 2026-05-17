import SwiftUI

struct SettingsView: View {
    @Environment(CityStore.self) var cityStore
    @AppStorage("app_color_scheme") private var colorSchemePreference = "auto"
    @AppStorage("app_locale") private var appLocale = ""
    @Environment(\.dismiss) private var dismiss

    private let languages: [(code: String, name: String)] = [
        ("", "settings_lang_system"),
        ("fr", "Français"),
        ("en", "English"),
        ("es", "Español"),
        ("it", "Italiano"),
        ("pt", "Português")
    ]

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // City
                Section(LocalizedStringKey("settings_section_city")) {
                    NavigationLink {
                        CityPickerView()
                            .environment(cityStore)
                    } label: {
                        HStack {
                            Label(LocalizedStringKey("settings_section_city"), systemImage: "mappin.circle.fill")
                            Spacer()
                            Text("\(cityStore.selectedCity.countryFlag) \(cityStore.selectedCity.localizedName)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Appearance
                Section(LocalizedStringKey("settings_section_appearance")) {
                    Picker(LocalizedStringKey("settings_section_appearance"), selection: $colorSchemePreference) {
                        Text("settings_theme_auto").tag("auto")
                        Text("settings_theme_light").tag("light")
                        Text("settings_theme_dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                // Language
                Section(LocalizedStringKey("settings_section_language")) {
                    ForEach(languages, id: \.code) { lang in
                        Button {
                            appLocale = lang.code
                        } label: {
                            HStack {
                                Text(lang.code.isEmpty ? LocalizedStringKey(lang.name) : LocalizedStringKey(lang.name))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if appLocale == lang.code {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.indigo)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                // About
                Section(LocalizedStringKey("settings_section_about")) {
                    HStack {
                        Text("settings_version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    Text(cityStore.selectedCity.provider.dataCredit)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("settings_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common_done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    SettingsView()
        .environment(CityStore())
}
