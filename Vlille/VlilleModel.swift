//
//  VlilleModel.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 13/02/2025.
//

// Modèle de données pour une station VLille
struct VLilleStation: Codable, Identifiable {
    var id: String { stationID }
    
    enum CodingKeys: String, CodingKey {
        case stationID = "@id"
        case nom, adresse, commune, etat, type
        case nbPlacesDispo = "nb_places_dispo"
        case nbVelosDispo = "nb_velos_dispo"
        case etatConnexion = "etat_connexion"
        case x, y, dateModification = "date_modification"
    }
    
    let stationID: String
    let nom: String
    let adresse: String
    let commune: String?
    let etat: String
    let type: String
    let nbPlacesDispo: Int
    let nbVelosDispo: Int
    let etatConnexion: String
    let x: Double
    let y: Double
    let dateModification: String
}

// Réponse JSON complète
struct VLilleModel: Codable {
    let numberMatched: Int
    let numberReturned: Int
    let records: [VLilleStation]
}
