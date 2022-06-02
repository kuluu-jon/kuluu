//
//  File.swift
//  
//
//  Created by kuluu-jon on 5/26/22.
//

import Foundation

public protocol ProvidesCharacter {
    var stats: FFXIMapPacket.CharacterStats { get }
}

public extension FFXIMapPacket {
    struct CharacterStats {
        
    }
}
