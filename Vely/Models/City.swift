import CoreLocation

struct City: Identifiable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let provider: CityProvider
    let serviceName: String
    let countryFlag: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Nom localisé selon la langue de l'app, fallback sur `name`
    var localizedName: String {
        NSLocalizedString("city_\(id)", value: name, comment: "")
    }

    static let lille = City(id: "lille", name: "Lille", latitude: 50.6292, longitude:  3.0573, provider: .vlille, serviceName: "VLille", countryFlag: "🇫🇷")
    static let all: [City] = [
        City(id: "amiens", name: "Amiens", latitude: 49.8941, longitude: 2.2958, provider: .jcdecaux(contractName: "amiens"), serviceName: "Velam", countryFlag: "🇫🇷"),
        City(id: "besancon", name: "Besançon", latitude: 47.2378, longitude: 6.0241, provider: .jcdecaux(contractName: "besancon"), serviceName: "VéloCité", countryFlag: "🇫🇷"),
        City(id: "bruxelles", name: "Bruxelles", latitude: 50.8503, longitude: 4.3517, provider: .jcdecaux(contractName: "bruxelles"), serviceName: "Villo!", countryFlag: "🇧🇪"),
        City(id: "cergy", name: "Cergy", latitude: 49.0369, longitude: 2.0739, provider: .jcdecaux(contractName: "cergy"), serviceName: "vél'02", countryFlag: "🇫🇷"),
        City(id: "dublin", name: "Dublin", latitude: 53.3498, longitude: 6.2603, provider: .jcdecaux(contractName: "dublin"), serviceName: "dublinbikes", countryFlag: "🇮🇪"),
        .lille,
        City(id: "lillestrom", name: "Lillestrøm", latitude: 59.9567, longitude: 11.0493, provider: .jcdecaux(contractName: "lillestrom"), serviceName: "Bysykkel", countryFlag: "🇳🇴"),
        City(id: "ljubljana",   name: "Ljubljana", latitude: 46.0569,  longitude: 14.5058, provider: .jcdecaux(contractName: "ljubljana"), serviceName: "BicikeLJ", countryFlag: "🇸🇮"),
        City(id: "lund", name: "Lund", latitude: 55.7047,  longitude: 13.1910,  provider: .jcdecaux(contractName: "lund"), serviceName: "Lundahoj", countryFlag: "🇸🇪"),
        City(id: "luxembourg", name: "Luxembourg", latitude: 49.6117,  longitude:  6.1319,  provider: .jcdecaux(contractName: "luxembourg"), serviceName: "Veloh", countryFlag: "🇱🇺"),
        City(id: "lyon", name: "Lyon", latitude: 45.7640,  longitude:  4.8357,  provider: .jcdecaux(contractName: "lyon"), serviceName: "Vélov'", countryFlag: "🇫🇷"),
        City(id: "maribor", name: "Maribor", latitude: 46.5547,  longitude: 15.6459,  provider: .jcdecaux(contractName: "maribor"), serviceName: "MBajk", countryFlag: "🇸🇮"),
        City(id: "mulhouse", name: "Mulhouse", latitude: 47.7508,  longitude:  7.3359,  provider: .jcdecaux(contractName: "mulhouse"), serviceName: "vélocité", countryFlag: "🇫🇷"),
        City(id: "nancy", name: "Nancy", latitude: 48.6921,  longitude:  6.1844,  provider: .jcdecaux(contractName: "nancy"), serviceName: "vélOstan'lib", countryFlag: "🇫🇷"),
        City(id: "namur", name: "Namur", latitude: 50.4674,  longitude:  4.8720,  provider: .jcdecaux(contractName: "namur"), serviceName: "Li Bia Vélo", countryFlag: "🇧🇪"),
        City(id: "nantes", name: "Nantes", latitude: 47.2184,  longitude: -1.5536,  provider: .jcdecaux(contractName: "nantes"), serviceName: "Naolib", countryFlag: "🇫🇷"),
        City(id: "paris", name: "Paris",  latitude: 48.8566, longitude:  2.3522,  provider: .velib, serviceName: "Vélib'", countryFlag: "🇫🇷"),
        City(id: "seville", name: "Séville", latitude: 37.3891,  longitude: -5.9845,  provider: .jcdecaux(contractName: "seville"), serviceName: "Sevici", countryFlag: "🇪🇸"),
        City(id: "toulouse", name: "Toulouse", latitude: 43.6047,  longitude:  1.4442,  provider: .jcdecaux(contractName: "toulouse"), serviceName: "VélôToulouse", countryFlag: "🇫🇷"),
        City(id: "toyama", name: "Toyama", latitude: 36.6953,  longitude: 137.2113, provider: .jcdecaux(contractName: "toyama"), serviceName: "Cyclocity", countryFlag: "🇯🇵"),
        City(id: "valence_es", name: "Valence", latitude: 39.4699,  longitude: -0.3763,  provider: .jcdecaux(contractName: "valence"), serviceName: "Valenbisi", countryFlag: "🇪🇸"),
        City(id: "vilnius", name: "Vilnius", latitude: 54.6872,  longitude: 25.2797,  provider: .jcdecaux(contractName: "vilnius"), serviceName: "Cyclocity", countryFlag: "🇱🇹")
    ]
}

enum CityProvider: Hashable {
    case vlille
    case velib
    case jcdecaux(contractName: String)

    private static let jcdecauxBase = "https://api.cyclocity.fr/contracts"

    var infoURL: URL? {
        switch self {
        case .vlille:
            return nil
        case .velib:
            return URL(string: "https://velib-metropole-opendata.smovengo.cloud/opendata/Velib_Metropole/station_information.json")
        case .jcdecaux(let contractName):
            return URL(string: "\(Self.jcdecauxBase)/\(contractName)/gbfs/v2/station_information.json")
        }
    }

    var statusURL: URL? {
        switch self {
        case .vlille:
            return URL(string: "https://data.lillemetropole.fr/geoserver/ogc/features/v1/collections/dsp_ilevia:vlille_temps_reel/items")
        case .velib:
            return URL(string: "https://velib-metropole-opendata.smovengo.cloud/opendata/Velib_Metropole/station_status.json")
        case .jcdecaux(let contractName):
            return URL(string: "\(Self.jcdecauxBase)/\(contractName)/gbfs/v2/station_status.json")
        }
    }

    var dataCredit: String {
        switch self {
        case .vlille:    return "© Métropole Européenne de Lille / Ilévia"
        case .velib:     return "© Vélib' Métropole / Smovengo"
        case .jcdecaux:  return "© JCDecaux CycloCity"
        }
    }
}
