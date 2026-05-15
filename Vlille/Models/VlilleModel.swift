//
//  VlilleModel.swift
//  Vlille
//
//  Created by Mohamed Amine AIT BELARBI on 13/02/2025.
//

// Réponse GeoJSON FeatureCollection
struct VLilleFeatureCollection: Codable {
    let features: [VLilleFeature]
}

struct VLilleFeature: Codable {
    let properties: VLilleStation
}

// Modèle de données pour une station VLille
struct VLilleStation: Codable, Identifiable, Hashable {
    var id: Int { identifiantStation }

    enum CodingKeys: String, CodingKey {
        case identifiantStation = "identifiant_station"
        case nom, adresse, commune, etat, type
        case nbPlacesDispo = "nb_places_dispo"
        case nbVelosDispo = "nb_velos_dispo"
        case etatConnexion = "etat_connexion"
        case x, y, dateModification = "date_modification"
    }

    let identifiantStation: Int
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
