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
    @ObservationIgnored private var currentRequestId: UUID = UUID()
    @ObservationIgnored private var autoRefreshTask: Task<Void, Never>?

    func switchCity(to city: City) {
        currentRequestId = UUID()
        autoRefreshTask?.cancel()
        currentCity = city
        stations = []
        errorMessage = nil
        fetchStations()
    }

    func startAutoRefresh() async {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task {
            fetchStations()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                fetchStations()
            }
        }
        await autoRefreshTask?.value
    }

    func fetchStations() {
        isLoading = true
        switch currentCity.provider {
        case .vlille:
            fetchVLilleStations()
        case .velib, .jcdecaux:
            guard let infoURL = currentCity.provider.infoURL,
                  let statusURL = currentCity.provider.statusURL else {
                isLoading = false
                return
            }
            fetchGBFSStations(infoURL: infoURL, statusURL: statusURL)
        case .citybike:
            guard let statusURL = currentCity.provider.statusURL else {
                isLoading = false
                return
            }
            fetchCitybikeStations(url: statusURL)
        }
    }

    func dismissError() { errorMessage = nil }

    // MARK: - Lille (GeoJSON + TLS delegate)

    private func fetchVLilleStations() {
        let requestId = currentRequestId
        guard let url = currentCity.provider.statusURL else {
            errorMessage = String(localized: "error_invalid_url")
            isLoading = false
            return
        }
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        session?.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self, self.currentRequestId == requestId else { return }
                self.isLoading = false
                if error != nil {
                    self.errorMessage = String(localized: "error_network")
                    return
                }
                guard let data else {
                    self.errorMessage = String(localized: "error_data_unavailable")
                    return
                }
                do {
                    let resp = try JSONDecoder().decode(VLilleFeatureCollection.self, from: data)
                    self.stations = resp.features.map { $0.properties.toBikeStation() }
                    self.lastUpdated = Date()
                } catch {
                    self.errorMessage = String(localized: "error_decoding")
                }
            }
        }.resume()
    }

    // MARK: - Generic GBFS (Vélib Paris + JCDecaux CycloCity)

    private func fetchGBFSStations(infoURL: URL, statusURL: URL) {
        let requestId = currentRequestId
        
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        guard let session else { return }
        Task { [weak self] in
            guard let self, self.currentRequestId == requestId else { return }
            do {
                async let infoReq   = session.data(from: infoURL)
                async let statusReq = session.data(from: statusURL)
                let (infoData, _)   = try await infoReq
                let (statusData, _) = try await statusReq
                guard self.currentRequestId == requestId else { return }
                let infoResp   = try JSONDecoder().decode(GBFSInfoResponse.self,   from: infoData)
                let statusResp = try JSONDecoder().decode(GBFSStatusResponse.self, from: statusData)
                let statusMap  = Dictionary(uniqueKeysWithValues: statusResp.data.stations.map { ($0.stationId, $0) })
                let cityId     = currentCity.id
                let stations   = infoResp.data.stations.compactMap { info -> BikeStation? in
                    guard let status = statusMap[info.stationId] else { return nil }
                    return status.toBikeStation(info: info, cityId: cityId)
                }
                await MainActor.run { [weak self] in
                    guard let self, self.currentRequestId == requestId else { return }
                    self.isLoading   = false
                    self.stations    = stations
                    self.lastUpdated = Date()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, self.currentRequestId == requestId else { return }
                    self.isLoading    = false
                    self.errorMessage = String(localized: "error_network")
                }
            }
        }
    }

    // MARK: - CityBike

    private func fetchCitybikeStations(url: URL) {
        let requestId = currentRequestId
        
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        guard let session else { return }
        Task { [weak self] in
            guard let self, self.currentRequestId == requestId else { return }
            do {
                let (data, _) = try await session.data(from: url)
                guard self.currentRequestId == requestId else { return }
                let response = try JSONDecoder().decode(CitybikeStationResponse.self, from: data)
                let cityId = currentCity.id
                let stations = response.network.stations.map { $0.toBikeStation(cityId: cityId) }
                await MainActor.run { [weak self] in
                    guard let self, self.currentRequestId == requestId else { return }
                    self.isLoading = false
                    self.stations = stations
                    self.lastUpdated = Date()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, self.currentRequestId == requestId else { return }
                    self.isLoading = false
                    self.errorMessage = String(localized: "error_network")
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
