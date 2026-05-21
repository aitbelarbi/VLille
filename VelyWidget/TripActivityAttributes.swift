import ActivityKit
import Foundation

enum StatusKind: Codable, Hashable {
    case bikes(Int)
    case weather(symbol: String, temp: String)
}

struct TripActivityAttributes: ActivityAttributes {
    let tripDisplayName: String
    let originName: String
    let destinationName: String

    struct ContentState: Codable, Hashable {
        let departureDate: Date
        let statusKind: StatusKind?
    }
}
