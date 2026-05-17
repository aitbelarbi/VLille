import Foundation

struct BikeStation: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let district: String?
    let latitude: Double
    let longitude: Double
    let bikesAvailable: Int
    let docksAvailable: Int
    let isOperational: Bool
    let stationType: String?
    let cityId: String
}
