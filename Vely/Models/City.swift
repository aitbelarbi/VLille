import CoreLocation

struct City: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let provider: CityProvider

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static let all: [City] = [.lille, .paris]

    static let lille = City(id: "lille", name: "Lille", latitude: 50.6292, longitude: 3.0573, provider: .vlille)
    static let paris = City(id: "paris", name: "Paris", latitude: 48.8566, longitude: 2.3522, provider: .velib)
}

enum CityProvider: String, Codable {
    case vlille
    case velib

    var dataCredit: String {
        switch self {
        case .vlille: return "© Métropole Européenne de Lille / Ilévia"
        case .velib: return "© Vélib' Métropole / Smovengo"
        }
    }
}
