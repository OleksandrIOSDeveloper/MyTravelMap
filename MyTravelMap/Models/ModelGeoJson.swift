//
//  ModelGeoJson.swift
//  MyTravelMap
//
//  Created by Oleksandr Roditeiliev on 01.10.2024.
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
    case polygon([[[Double]]])        // For Polygon
    case multiPolygon([[[[Double]]]]) // For MultiPolygon
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as MultiPolygonn
        if let multiPolygon = try? container.decode([[[[Double]]]].self) {
            self = .multiPolygon(multiPolygon)
            return
        }
        
        // Try to decode as Polygon
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




