//
//  ZoneMetadata.swift
//
//
//  Created by jon on 6/17/22.
//

import Foundation

public enum ZoneMetadataType: String, Codable {
    case fishing = "Fishing area"
    case zoneLine = "ZoneLine"
    case doorOrObject = "Door or Object"
    case event = "Event"
    case elevator = "Elevators"
    case model = "Model"
}

public struct ArrayOfSubRegion: Codable {
    public var zoneMetadatas: [ZoneMetadata]
    
    public enum CodingKeys: String, CodingKey {
        case zoneMetadatas = "SubRegion"
    }
}

public struct ZoneMetadata: Codable, Identifiable {
    public let fileId: Int
    public let id: String
    
    public let positionX: Float
    public let positionY: Float
    public let positionZ: Float
    
    public lazy var simdPosition: SIMD3<Float> = {
        .init(x: positionX, y: positionY, z: positionZ)
    }()
    
    public let rotationX: Float
    public let rotationY: Float
    public let rotationZ: Float
    
    public lazy var simdRotation: SIMD3<Float> = {
        .init(x: rotationX, y: rotationY, z: rotationZ)
    }()
    
    public let scaleX: Float
    public let scaleY: Float
    public let scaleZ: Float
    
    public lazy var simdScale: SIMD3<Float> = {
        .init(x: scaleX, y: scaleY, z: scaleZ)
    }()
    
    public let type: ZoneMetadataType?
    
    public enum CodingKeys: String, CodingKey {
        case id = "Identifier"
        case fileId = "FileId"
        case positionX = "X"
        case positionY = "Y"
        case positionZ = "Z"
        case rotationX = "RotationX"
        case rotationY = "RotationY"
        case rotationZ = "RotationZ"
        case scaleX = "ScaleX"
        case scaleY = "ScaleY"
        case scaleZ = "ScaleZ"
        case type = "Type"
    }
}
