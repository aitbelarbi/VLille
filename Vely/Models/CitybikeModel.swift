import Foundation

// MARK: - Network List (for loading all cities)

struct CitybikeNetworkListResponse: Codable {
    let networks: [CitybikeNetworkEntry]
}

struct CitybikeNetworkEntry: Codable {
    let id: String
    let name: String
    let location: CitybikeLocation
    let company: [String]?
    let gbfsHref: String?

    enum CodingKeys: String, CodingKey {
        case id, name, location, company
        case gbfsHref = "gbfs_href"
    }

    func toCity() -> City {
        City(
            id: "cb_\(id)",
            name: location.city,
            latitude: location.latitude,
            longitude: location.longitude,
            provider: .citybike(networkId: id),
            serviceName: name,
            countryCode: location.country
        )
    }
}

struct CitybikeLocation: Codable {
    let latitude: Double
    let longitude: Double
    let city: String
    let country: String
}

// MARK: - Station Data (for fetching stations in a city)

struct CitybikeStationResponse: Codable {
    let network: CitybikeStationNetwork
}

struct CitybikeStationNetwork: Codable {
    let stations: [CitybikeStation]
}

struct CitybikeStation: Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let freeBikes: Int
    let emptySlots: Int?
    let extra: CitybikeExtra?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, extra
        case freeBikes = "free_bikes"
        case emptySlots = "empty_slots"
    }

    func toBikeStation(cityId: String) -> BikeStation {
        let available = freeBikes
        let free = emptySlots ?? 0
        return BikeStation(
            id: "\(cityId)_\(id)",
            name: name,
            address: name,
            district: nil,
            latitude: latitude,
            longitude: longitude,
            bikesAvailable: available,
            docksAvailable: free,
            isOperational: extra?.installed ?? true,
            stationType: nil,
            cityId: cityId
        )
    }
}

struct CitybikeExtra: Codable {
    let installed: Bool?
    let normalBikes: Int?
    let ebikes: Int?

    enum CodingKeys: String, CodingKey {
        case installed
        case normalBikes = "normal_bikes"
        case ebikes
    }
}
