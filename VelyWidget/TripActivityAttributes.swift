import ActivityKit
import Foundation

struct TripActivityAttributes: ActivityAttributes {
    let tripDisplayName: String
    let originName: String
    let destinationName: String

    struct ContentState: Codable, Hashable {
        let departureDate: Date
        let bikesAvailable: Int?
    }
}
