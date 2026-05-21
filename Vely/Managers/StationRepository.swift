import Foundation

final class StationRepository: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    func fetch(city: City) async throws -> [BikeStation] {
        switch city.provider {
        case .vlille:
            return try await fetchVLille(city: city)
        case .velib, .jcdecaux:
            guard let infoURL = city.provider.infoURL,
                  let statusURL = city.provider.statusURL else { throw URLError(.badURL) }
            return try await fetchGBFS(city: city, infoURL: infoURL, statusURL: statusURL)
        case .citybike:
            guard let statusURL = city.provider.statusURL else { throw URLError(.badURL) }
            return try await fetchCitybike(city: city, url: statusURL)
        case .unsupported:
            return []
        }
    }

    // MARK: - VLille

    private func fetchVLille(city: City) async throws -> [BikeStation] {
        guard let url = city.provider.statusURL else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        let response  = try JSONDecoder().decode(VLilleFeatureCollection.self, from: data)
        return response.features.map { $0.properties.toBikeStation() }
    }

    // MARK: - GBFS (Vélib + JCDecaux)

    private func fetchGBFS(city: City, infoURL: URL, statusURL: URL) async throws -> [BikeStation] {
        async let infoReq   = session.data(from: infoURL)
        async let statusReq = session.data(from: statusURL)
        let (infoData, _)   = try await infoReq
        let (statusData, _) = try await statusReq
        let infoResp   = try JSONDecoder().decode(GBFSInfoResponse.self,   from: infoData)
        let statusResp = try JSONDecoder().decode(GBFSStatusResponse.self, from: statusData)
        let statusMap  = Dictionary(uniqueKeysWithValues: statusResp.data.stations.map { ($0.stationId, $0) })
        return infoResp.data.stations.compactMap { info in
            guard let status = statusMap[info.stationId] else { return nil }
            return status.toBikeStation(info: info, cityId: city.id)
        }
    }

    // MARK: - CityBike

    private func fetchCitybike(city: City, url: URL) async throws -> [BikeStation] {
        let (data, _) = try await session.data(from: url)
        let response  = try JSONDecoder().decode(CitybikeStationResponse.self, from: data)
        return response.network.stations.map { $0.toBikeStation(cityId: city.id) }
    }

    // MARK: - TLS bypass (Zscaler / corporate proxy)

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleChallenge(challenge, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleChallenge(challenge, completionHandler: completionHandler)
    }

    private func handleChallenge(_ challenge: URLAuthenticationChallenge,
                                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
#if DEBUG
        var error: CFError?
        SecTrustEvaluateWithError(trust, &error)
        completionHandler(.useCredential, URLCredential(trust: trust))
#else
        completionHandler(.performDefaultHandling, nil)
#endif
    }
}
