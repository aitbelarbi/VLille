//
//  VelibModel+Paris.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 17/05/2026.
//

// MARK: - Generic GBFS models (Vélib Paris + JCDecaux CycloCity)

struct GBFSInfoResponse: Decodable {
    struct DataWrapper: Decodable {
        let stations: [GBFSStationInfo]
    }
    let data: DataWrapper
}

struct GBFSStationInfo: Decodable {
    let stationId: String
    let name: String
    let lat: Double
    let lon: Double
    let address: String?

    enum CodingKeys: String, CodingKey {
        case stationId = "station_id"
        case name, lat, lon, address
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Handle both String and Int station_id (Vélib sends Int, JCDecaux sends String)
        if let s = try? c.decode(String.self, forKey: .stationId) {
            stationId = s
        } else {
            stationId = try String(c.decode(Int.self, forKey: .stationId))
        }
        name    = try c.decode(String.self, forKey: .name)
        lat     = try c.decode(Double.self, forKey: .lat)
        lon     = try c.decode(Double.self, forKey: .lon)
        address = try? c.decode(String.self, forKey: .address)
    }
}

struct GBFSStatusResponse: Decodable {
    struct DataWrapper: Decodable {
        let stations: [GBFSStationStatus]
    }
    let data: DataWrapper
}

struct GBFSStationStatus: Decodable {
    let stationId: String
    let numBikesAvailable: Int
    let numDocksAvailable: Int
    let isInstalled: Bool
    let isRenting: Bool

    enum CodingKeys: String, CodingKey {
        case stationId = "station_id"
        case numBikesAvailable = "num_bikes_available"
        case numDocksAvailable = "num_docks_available"
        case isInstalled = "is_installed"
        case isRenting = "is_renting"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .stationId) {
            stationId = s
        } else {
            stationId = try String(c.decode(Int.self, forKey: .stationId))
        }
        numBikesAvailable = (try? c.decode(Int.self, forKey: .numBikesAvailable)) ?? 0
        numDocksAvailable = (try? c.decode(Int.self, forKey: .numDocksAvailable)) ?? 0
        // Handle both Bool and Int (0/1) for is_installed/is_renting
        if let b = try? c.decode(Bool.self, forKey: .isInstalled) { isInstalled = b }
        else { isInstalled = (try? c.decode(Int.self, forKey: .isInstalled)) == 1 }
        if let b = try? c.decode(Bool.self, forKey: .isRenting) { isRenting = b }
        else { isRenting = (try? c.decode(Int.self, forKey: .isRenting)) == 1 }
    }

    func toBikeStation(info: GBFSStationInfo, cityId: String) -> BikeStation {
        BikeStation(
            id: "\(cityId)_\(stationId)",
            name: info.name,
            address: info.address ?? info.name,
            district: nil,
            latitude: info.lat,
            longitude: info.lon,
            bikesAvailable: numBikesAvailable,
            docksAvailable: numDocksAvailable,
            isOperational: isInstalled && isRenting,
            stationType: nil,
            cityId: cityId
        )
    }
}
