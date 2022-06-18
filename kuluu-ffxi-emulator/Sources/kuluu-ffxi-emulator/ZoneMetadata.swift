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

public struct ZoneMetadata: Codable {
    public let fileId: UInt
    public let identifier: String
    
    public let rotationX: Float
    public let rotationY: Float
    public let rotationZ: Float
    
    public let scaleX: Float
    public let scaleY: Float
    public let scaleZ: Float
    
    public let type: ZoneMetadataType
}

public struct ZoneMetadataContainer: Codable {
    public let arrayOfSubRegion: [ZoneMetadata]
}

