//
//  ZoneEntity.swift
//  
//
//  Created by jon on 6/17/22.
//

import Foundation
import XMLCoder
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

let xmlDecoder: XMLDecoder = {
    let xmlDecoder = XMLDecoder()
//    xmlDecoder.keyDecodingStrategy = .convertFromCapitalized
//    xmlDecoder.shouldProcessNamespaces = false
//    xmlDecoder.removeWhitespaceElements = false
//    xmlDecoder.trimValueWhitespaces = false
    return xmlDecoder
}()

public struct ZoneDescriptor {
    internal init(entity: [Entity]? = nil, zoneMetadatas: [ZoneMetadata]? = nil) {
        self.entity = entity
        self.zoneMetadatas = zoneMetadatas
    }
    
    public var entity: [Entity]?
    public var zoneMetadatas: [ZoneMetadata]?
}

public func loadEntities() async throws -> [Int: ZoneDescriptor] {
    // swift can be fast if u use all da cores, watch this.
    // load all of the xml file urls in our resources
    let urls = Bundle.module.urls(forResourcesWithExtension: "xml", subdirectory: "Data")
    // pair urls with their data contents so we can process different urls differently if needed
    // (e.g. subregion vs. entities)
    let dataUrlTuples = try await urls?.concurrentCompactMap { url -> (Data, URL) in
        (try Data(contentsOf: url), url)
    }
    // grab entity XMLs (and discard subregions for now) concurrently
    enum DataType {
        case entity(Data), subregion(Data)
        
        init?(tuple: (Data, URL)) {
            let lastPath = tuple.1.lastPathComponent
            if lastPath.hasSuffix("_Entities.xml") {
                self = .entity(tuple.0)
            } else if lastPath.hasSuffix("_SubRegions.xml") {
                self = .subregion(tuple.0)
            } else {
                fatalError("unhandled xml file: \(lastPath)")
            }
        }
    }
    let entityDataTypes = await dataUrlTuples?.concurrentCompactMap(DataType.init(tuple:))
    // decode XML concurrently
    let entities = try await entityDataTypes?.concurrentCompactMap { dataType -> ZoneDescriptor? in
        switch dataType {
        case .subregion(let data):
            let zoneXML = try xmlDecoder.decode(ArrayOfSubRegion.self, from: data)
            let zoneMetadatas = zoneXML.zoneMetadatas
            return ZoneDescriptor(entity: nil, zoneMetadatas: zoneMetadatas)
        case .entity(let data):
            let zoneXML = try xmlDecoder.decode(ArrayOfEntity.self, from: data)
            let entities = zoneXML.entities
            return ZoneDescriptor(entity: entities, zoneMetadatas: nil)
        }
    }
    var entityMap: [Int: ZoneDescriptor] = .init(minimumCapacity: entities?.count ?? 600)
    await entities?.asyncForEach { row in
        if let firstEntity = row.entity?.first {
//            assert(firstEntity.zoneId == firstZoneMetadata.fileId)
            let zoneId = firstEntity.zoneId
            if var zoneDescriptor = entityMap[zoneId] {
                zoneDescriptor.entity = row.entity!
                entityMap[zoneId] = zoneDescriptor
            } else {
                entityMap[zoneId] = .init(entity: row.entity!, zoneMetadatas: nil)
            }
        } else if let firstZoneMetadata = row.zoneMetadatas?.first {
            let zoneId = firstZoneMetadata.fileId
            if var zoneDescriptor = entityMap[zoneId] {
                zoneDescriptor.zoneMetadatas = row.zoneMetadatas!
                entityMap[zoneId] = zoneDescriptor
            } else {
                entityMap[zoneId] = .init(entity: nil, zoneMetadatas: row.zoneMetadatas!)
            }
        }
    }
    
    return entityMap
}
