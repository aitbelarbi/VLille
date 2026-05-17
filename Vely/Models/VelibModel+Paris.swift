//
//  VelibModel+Paris.swift
//  Vely
//
//  Created by Mohamed Amine AIT BELARBI on 17/05/2026.
//


struct VelibInfoResponse: Codable {
    let data: VelibInfoData
}

struct VelibInfoData: Codable {
    let stations: [VelibStationInfo]
}

struct VelibStationInfo: Codable {
    let stationId: Int
    let name: String
    let lat: Double
    let lon: Double

    enum CodingKeys: String, CodingKey {
        case stationId = "station_id"
        case name, lat, lon
    }
}

struct VelibStatusResponse: Codable {
    let data: VelibStatusData
}

struct VelibStatusData: Codable {
    let stations: [VelibStationStatus]
}

struct VelibStationStatus: Codable {
    let stationId: Int
    let numBikesAvailable: Int
    let numDocksAvailable: Int
    let isInstalled: Int
    let isRenting: Int

    enum CodingKeys: String, CodingKey {
        case stationId = "station_id"
        case numBikesAvailable = "num_bikes_available"
        case numDocksAvailable = "num_docks_available"
        case isInstalled = "is_installed"
        case isRenting = "is_renting"
    }

    func toBikeStation(info: VelibStationInfo) -> BikeStation {
        BikeStation(
            id: "paris_\(stationId)",
            name: info.name,
            address: info.name,
            district: nil,
            latitude: info.lat,
            longitude: info.lon,
            bikesAvailable: numBikesAvailable,
            docksAvailable: numDocksAvailable,
            isOperational: isInstalled == 1 && isRenting == 1,
            stationType: nil,
            cityId: "paris"
        )
    }
}
