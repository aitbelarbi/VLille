//
//  HomeViewModel.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 13/02/2025.
//

import Foundation

// ViewModel qui récupère les données
class HomeViewModel: NSObject, ObservableObject, URLSessionDelegate, URLSessionTaskDelegate {
    @Published var stations: [VLilleStation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    private var session: URLSession?

    let url = "https://data.lillemetropole.fr/geoserver/ogc/features/v1/collections/dsp_ilevia:vlille_temps_reel/items"

    func startAutoRefresh() async {
        fetchStations()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { break }
            fetchStations()
        }
    }
    
    func fetchStations() {
        guard let requestUrl = URL(string: url) else {
            self.errorMessage = "URL invalide"
            return
        }
        
        isLoading = true
        
        // Configuration de la session pour ignorer les erreurs SSL (DEV ONLY)
        // On garde une référence forte à la session pour éviter qu'elle ne soit libérée
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        
        session?.dataTask(with: requestUrl) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Erreur réseau: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "Données non disponibles"
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(VLilleFeatureCollection.self, from: data)
                    self?.stations = decodedResponse.features.map { $0.properties }
                    self?.lastUpdated = Date()
                } catch {
                    self?.errorMessage = "Erreur de décodage: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // MARK: - URLSessionDelegate (session-level)
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleChallenge(challenge, completionHandler: completionHandler)
    }
    
    // MARK: - URLSessionTaskDelegate (task-level, requis sur iOS 17+)
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleChallenge(challenge, completionHandler: completionHandler)
    }
    
    // DANGER: Contourne la vérification TLS. À utiliser UNIQUEMENT en développement.
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
