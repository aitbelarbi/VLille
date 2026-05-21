import CoreLocation
import MapKit

struct City: Identifiable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let provider: CityProvider
    let serviceName: String
    let countryCode: String

    var countryFlag: String {
        countryCode.uppercased().unicodeScalars
            .compactMap { Unicode.Scalar($0.value + 127397) }
            .map { String($0) }
            .joined()
    }

    var countryName: String {
        Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Nom localisé selon la langue de l'app, fallback sur `name`
    var localizedName: String {
        NSLocalizedString("city_\(id)", value: name, comment: "")
    }

    static func unsupported(from placemark: MKPlacemark) -> City {
        let name = placemark.locality ?? placemark.administrativeArea ?? placemark.name ?? ""
        let id = "custom_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
        return City(
            id: id,
            name: name,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude,
            provider: .unsupported,
            serviceName: "",
            countryCode: placemark.isoCountryCode ?? ""
        )
    }

    static let lille = City(id: "lille", name: "Lille", latitude: 50.6292, longitude: 3.0573, provider: .vlille, serviceName: "VLille", countryCode: "FR")
    static let staticAll: [City] = [
        City(id: "amiens",     name: "Amiens",     latitude: 49.8941, longitude:   2.2958, provider: .jcdecaux(contractName: "amiens"),     serviceName: "Velam",         countryCode: "FR"),
        City(id: "besancon",   name: "Besançon",   latitude: 47.2378, longitude:   6.0241, provider: .jcdecaux(contractName: "besancon"),   serviceName: "VéloCité",      countryCode: "FR"),
        City(id: "bruxelles",  name: "Bruxelles",  latitude: 50.8503, longitude:   4.3517, provider: .jcdecaux(contractName: "bruxelles"),  serviceName: "Villo!",        countryCode: "BE"),
        City(id: "cergy",      name: "Cergy",      latitude: 49.0369, longitude:   2.0739, provider: .jcdecaux(contractName: "cergy"),      serviceName: "vél'02",        countryCode: "FR"),
        City(id: "dublin",     name: "Dublin",     latitude: 53.3498, longitude:  -6.2603, provider: .jcdecaux(contractName: "dublin"),     serviceName: "dublinbikes",   countryCode: "IE"),
        .lille,
        City(id: "lillestrom", name: "Lillestrøm", latitude: 59.9567, longitude:  11.0493, provider: .jcdecaux(contractName: "lillestrom"), serviceName: "Bysykkel",      countryCode: "NO"),
        City(id: "ljubljana",  name: "Ljubljana",  latitude: 46.0569, longitude:  14.5058, provider: .jcdecaux(contractName: "ljubljana"),  serviceName: "BicikeLJ",      countryCode: "SI"),
        City(id: "lund",       name: "Lund",       latitude: 55.7047, longitude:  13.1910, provider: .jcdecaux(contractName: "lund"),       serviceName: "Lundahoj",      countryCode: "SE"),
        City(id: "luxembourg", name: "Luxembourg", latitude: 49.6117, longitude:   6.1319, provider: .jcdecaux(contractName: "luxembourg"), serviceName: "Veloh",         countryCode: "LU"),
        City(id: "lyon",       name: "Lyon",       latitude: 45.7640, longitude:   4.8357, provider: .jcdecaux(contractName: "lyon"),       serviceName: "Vélov'",        countryCode: "FR"),
        City(id: "maribor",    name: "Maribor",    latitude: 46.5547, longitude:  15.6459, provider: .jcdecaux(contractName: "maribor"),    serviceName: "MBajk",         countryCode: "SI"),
        City(id: "mulhouse",   name: "Mulhouse",   latitude: 47.7508, longitude:   7.3359, provider: .jcdecaux(contractName: "mulhouse"),   serviceName: "vélocité",      countryCode: "FR"),
        City(id: "nancy",      name: "Nancy",      latitude: 48.6921, longitude:   6.1844, provider: .jcdecaux(contractName: "nancy"),      serviceName: "vélOstan'lib",  countryCode: "FR"),
        City(id: "namur",      name: "Namur",      latitude: 50.4674, longitude:   4.8720, provider: .jcdecaux(contractName: "namur"),      serviceName: "Li Bia Vélo",   countryCode: "BE"),
        City(id: "nantes",     name: "Nantes",     latitude: 47.2184, longitude:  -1.5536, provider: .jcdecaux(contractName: "nantes"),     serviceName: "Naolib",        countryCode: "FR"),
        City(id: "paris",      name: "Paris",      latitude: 48.8566, longitude:   2.3522, provider: .velib,                               serviceName: "Vélib'",        countryCode: "FR"),
        City(id: "seville",    name: "Séville",    latitude: 37.3891, longitude:  -5.9845, provider: .jcdecaux(contractName: "seville"),    serviceName: "Sevici",        countryCode: "ES"),
        City(id: "toulouse",   name: "Toulouse",   latitude: 43.6047, longitude:   1.4442, provider: .jcdecaux(contractName: "toulouse"),   serviceName: "VélôToulouse",  countryCode: "FR"),
        City(id: "toyama",     name: "Toyama",     latitude: 36.6953, longitude: 137.2113, provider: .jcdecaux(contractName: "toyama"),     serviceName: "Cyclocity",     countryCode: "JP"),
        City(id: "valence_es", name: "Valence",    latitude: 39.4699, longitude:  -0.3763, provider: .jcdecaux(contractName: "valence"),    serviceName: "Valenbisi",     countryCode: "ES"),
        City(id: "vilnius",    name: "Vilnius",    latitude: 54.6872, longitude:  25.2797, provider: .jcdecaux(contractName: "vilnius"),    serviceName: "Cyclocity",     countryCode: "LT"),
    ]
}

extension String {
    var flagEmoji: String {
        self.uppercased().unicodeScalars
            .compactMap { Unicode.Scalar($0.value + 127397) }
            .map { String($0) }
            .joined()
    }
}

enum CityProvider: Hashable {
    case vlille
    case velib
    case jcdecaux(contractName: String)
    case citybike(networkId: String)
    case unsupported

    private static let jcdecauxBase = "https://api.cyclocity.fr/contracts"

    var infoURL: URL? {
        switch self {
        case .vlille:
            return nil
        case .velib:
            return URL(string: "https://velib-metropole-opendata.smovengo.cloud/opendata/Velib_Metropole/station_information.json")
        case .jcdecaux(let contractName):
            return URL(string: "\(Self.jcdecauxBase)/\(contractName)/gbfs/v2/station_information.json")
        case .citybike:
            return nil
        case .unsupported:
            return nil
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
        case .citybike(let networkId):
            return URL(string: "https://api.citybik.es/v2/networks/\(networkId)?fields=stations")
        case .unsupported:
            return nil
        }
    }

    var dataCredit: String {
        switch self {
        case .vlille:       return "© Métropole Européenne de Lille / Ilévia"
        case .velib:        return "© Vélib' Métropole / Smovengo"
        case .jcdecaux:     return "© JCDecaux CycloCity"
        case .citybike:     return "© CityBikes contributors"
        case .unsupported:  return ""
        }
    }

    var isSupported: Bool { self != .unsupported }
}
