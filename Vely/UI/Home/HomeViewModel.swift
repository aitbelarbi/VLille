//
//  HomeViewModel.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 13/02/2025.
//

import Foundation
import Observation

@Observable
class HomeViewModel: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    var stations: [BikeStation] = []
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?
    var currentCity: City = .lille

    @ObservationIgnored private var session: URLSession?

    private let vlilleURL = "https://data.lillemetropole.fr/geoserver/ogc/features/v1/collections/dsp_ilevia:vlille_temps_reel/items"
    private let velibInfoURL = "https://velib-metropole-opendata.smovengo.cloud/opendata/Velib_Metropole/station_information.json"
    private let velibStatusURL = "https://velib-metropole-opendata.smovengo.cloud/opendata/Velib_Metropole/station_status.json"

    func switchCity(to city: City) {
        currentCity = city
        stations = []
        errorMessage = nil
        fetchStations()
    }

    func startAutoRefresh() async {
        fetchStations()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { break }
            fetchStations()
        }
    }

    func fetchStations() {
        isLoading = true
        switch currentCity.provider {
        case .vlille: fetchVLilleStations()
        case .velib:  fetchVelibStations()
        }
    }

    func dismissError() { errorMessage = nil }

    // MARK: - Lille (GeoJSON + TLS delegate)

    private func fetchVLilleStations() {
        guard let url = URL(string: vlilleURL) else {
            errorMessage = String(localized: "error_invalid_url")
            isLoading = false
            return
        }
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        session?.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if error != nil {
                    self?.errorMessage = String(localized: "error_network")
                    return
                }
                guard let data else {
                    self?.errorMessage = String(localized: "error_data_unavailable")
                    return
                }
                do {
                    let resp = try JSONDecoder().decode(VLilleFeatureCollection.self, from: data)
                    self?.stations = resp.features.map { $0.properties.toBikeStation() }
                    self?.lastUpdated = Date()
                } catch {
                    self?.errorMessage = String(localized: "error_decoding")
                }
            }
        }.resume()
    }

    // MARK: - Vélib Paris (GBFS, two concurrent endpoints)

    private func fetchVelibStations() {
        guard let infoURL = URL(string: velibInfoURL),
              let statusURL = URL(string: velibStatusURL) else {
            errorMessage = String(localized: "error_invalid_url")
            isLoading = false
            return
        }
        Task {
            do {
                async let infoReq = URLSession.shared.data(from: infoURL)
                async let statusReq = URLSession.shared.data(from: statusURL)
                let (infoData, _) = try await infoReq
                let (statusData, _) = try await statusReq

                let infoResp = try JSONDecoder().decode(VelibInfoResponse.self, from: infoData)
                let statusResp = try JSONDecoder().decode(VelibStatusResponse.self, from: statusData)

                let statusMap = Dictionary(uniqueKeysWithValues: statusResp.data.stations.map { ($0.stationId, $0) })
                let stations = infoResp.data.stations.compactMap { info -> BikeStation? in
                    guard let status = statusMap[info.stationId] else { return nil }
                    return status.toBikeStation(info: info)
                }
                await MainActor.run { [weak self] in
                    self?.isLoading = false
                    self?.stations = stations
                    self?.lastUpdated = Date()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = String(localized: "error_network")
                }
            }
        }
    }

    // MARK: - URLSessionDelegate (TLS bypass for Lille / corporate proxy)

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleChallenge(challenge, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleChallenge(challenge, completionHandler: completionHandler)
    }

    private func handleChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        var error: CFError?
        SecTrustEvaluateWithError(trust, &error)
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
