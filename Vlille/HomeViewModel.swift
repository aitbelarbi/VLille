//
//  HomeViewModel.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 13/02/2025.
//

import Foundation

// ViewModel qui récupère les données
class HomeViewModel: ObservableObject {
    @Published var stations: [VLilleStation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let url = "https://data.lillemetropole.fr/data/ogcapi/collections/ilevia:vlille_temps_reel/items?f=json&limit=-1"
    
    func fetchStations() {
        guard let requestUrl = URL(string: url) else {
            self.errorMessage = "URL invalide"
            return
        }
        print("hereeee")
        isLoading = true
        URLSession.shared.dataTask(with: requestUrl) { [weak self] data, response, error in
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
                    let decodedResponse = try JSONDecoder().decode(VLilleModel.self, from: data)
                    self?.stations = decodedResponse.records
                } catch {
                    self?.errorMessage = "Erreur de décodage: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
