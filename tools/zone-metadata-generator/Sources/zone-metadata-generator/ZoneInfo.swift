//
//  ZoneInfo.swift
//  copied from noesis-scene-generator
//
//  Created by jon on 6/9/22.
//

import Foundation

struct ZoneInfoContainer: Decodable {
    let zoneInfo: [ZoneInfo]
}

struct ZoneInfo: Decodable, Identifiable {
    let id: Int
    let name: String
    let bumpMapDatPath: String?
    let mainModelDatPath: String?
    let shadowDatPath: String?
    let entityDatPath: String?
    let dialogueDatPath: String?
    let eventDatPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case bumpMapDatPath = "BumpMap_Dat_Path"
        case mainModelDatPath = "Main_Model_Dat_Path"
        case shadowDatPath = "Shodow_Dat_Path"
        case entityDatPath = "Entity_Dat_Path"
        case dialogueDatPath = "Dialogue_Dat_Path"
        case eventDatPath = "Event_Dat_Path"
    }
    
    private var mainMapObject: String? {
        if let mainModelDatPath = mainModelDatPath {
            return """
            object
            {
              name "\(name)"
              model "\(mainModelDatPath)"
              loadOptions "-ff11blendhack 0.99 -ff11keepnames 1"
            }
            """
        } else {
            return nil
        }
    }
    
    private var bumpMapObject: String? {
        if let bumpMapDatPath = bumpMapDatPath {
            return """
            object
            {
              name "\(name) BumpMap"
              model "\(bumpMapDatPath)"
              loadOptions "-ff11blendhack 0.99 -ff11keepnames 1"
            }
            """
        } else {
            return nil
        }
    }
    
    var noesisScene: (String, Int)? {
        let mainMapObject = self.mainMapObject
        let bumpMapObject = self.bumpMapObject
        guard mainMapObject != nil || bumpMapObject != nil else {
            return nil
        }
        return ("""
        NOESIS_SCENE_FILE
        version 1
        physicslib ""
        defaultAxis "0"
        \(mainMapObject ?? "")
        \(bumpMapObject ?? "")
        """, id)
    }
}
