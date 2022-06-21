//
//  ZoneEntity.swift
//  
//
//  Created by jon on 6/17/22.
//

import Foundation
import CollectionConcurrencyKit

public struct ArrayOfEntity: Codable {
    public var entities: [Entity]
    
    public enum CodingKeys: String, CodingKey {
        case entities = "Entity"
    }
}

public struct Entity: Codable {
    public var name: String
    public var serverId: Int
    public var targetIndex: Int
    public var zoneId: Int
    
    public enum CodingKeys: String, CodingKey {
        case name = "Name"
        case serverId = "ServerId"
        case targetIndex = "TargetIndex"
        case zoneId = "ZoneId"
            
    }
}
