//
//  ModelGeoJson.swift
//  MyTravelMap
//
//  Created by Александр Родителев on 01.10.2024.
//

import Foundation

struct GeoJSONProperties: Codable {
    let name: String?
}

struct GeoJSONGeometry: Codable {
    let type: String?
    let coordinates: GeoJSONCoordinates
}

enum GeoJSONCoordinates: Codable {
    case polygon([[[Double]]])        // Для Polygon
    case multiPolygon([[[[Double]]]]) // Для MultiPolygon
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Пробуем декодировать как MultiPolygon
        if let multiPolygon = try? container.decode([[[[Double]]]].self) {
            self = .multiPolygon(multiPolygon)
            return
        }
        
        // Пробуем декодировать как Polygon
        if let polygon = try? container.decode([[[Double]]].self) {
            self = .polygon(polygon)
            return
        }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown coordinates format.")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .polygon(let coordinates):
            try container.encode(coordinates)
        case .multiPolygon(let coordinates):
            try container.encode(coordinates)
        }
    }
}

struct GeoJSONFeature: Codable {
    let type: String?
    let id: String?
    let properties: GeoJSONProperties?
    let geometry: GeoJSONGeometry?
}

struct GeoJSON: Codable {
    let type: String
    let features: [GeoJSONFeature]
}




