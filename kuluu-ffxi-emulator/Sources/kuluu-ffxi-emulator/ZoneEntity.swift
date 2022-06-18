//
//  ZoneEntity.swift
//  
//
//  Created by jon on 6/17/22.
//

import Foundation
import XMLCoder
import CollectionConcurrencyKit

public struct ZoneEntityContainer: Codable {
    public let arrayOfEntity: [ZoneEntity]
}

public struct ZoneEntity: Codable {
    public let name: String
    public let serverId: UInt
    public let targetId: UInt
    public let zoneId: UInt
}

let xmlDecoder = XMLDecoder()
// swift can be fast if u use da cores
public func loadEntitiesForZone(id: Int) async throws -> [UInt: [ZoneEntity]] {
    let url = Bundle.module.resourceURL
    
    print(url)
    
    let urls = Bundle.module.urls(forResourcesWithExtension: "xml", subdirectory: "Data")
    let datas = try await urls?.concurrentCompactMap { url -> Data in
        try Data(contentsOf: url)
    }
    let entities = try await datas?.concurrentCompactMap { data -> [ZoneEntity] in
        let zoneEntityContainer = try xmlDecoder.decode(ZoneEntityContainer.self, from: data)
        let entities = zoneEntityContainer.arrayOfEntity
        print(entities)
        return entities
    }
    
    var entityMap: [UInt: [ZoneEntity]] = [:]
    
    await entities?.concurrentForEach { entities in
        if let zoneId = entities.first?.zoneId {
            entityMap[zoneId] = entities
        }
    }
    
    return entityMap
}
