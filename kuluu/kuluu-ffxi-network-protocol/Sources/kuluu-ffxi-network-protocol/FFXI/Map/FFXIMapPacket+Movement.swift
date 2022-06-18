//
//  File.swift
//  
//
//  Created by kuluu-jon on 5/19/22.
//

import Foundation
import simd
import BinaryCodable

public protocol ProvidesMapMovement {
    func sync(position: SIMD3<Float>, rotation: Float) async throws
}

// MARK: Client -> Server

public extension FFXIMapPacket {

    struct PlayerSyncRequest: FFXIPacket {

        public var header: EmptyPacketHeader {
            .init(sendCount: sendCount)
        }

        public let id: UInt16 = 0x15
        public let size: UInt8 = 0x10
        public let isBodyEncrypted: Bool = false
        public let sendCount: UInt16
        let position: SIMD3<Float>
        let isMoving: UInt16 = 1
        let rotation: Float
        let targetId: UInt16

        public func encode(to encoder: BinaryEncoder) throws {
            var c = encoder.container()
//            let pad1 = [UInt8](repeating: .zero, count: 2)
//            try c.encode(sequence: pad1)
            try c.encode(-position.x)
            try c.encode(position.y)
            try c.encode(position.z)
            try c.encode(UInt16(0x0)) // pad1
            try c.encode(isMoving) // ?speed/footsteps

            let rawDegrees = (rotation) * (360 / .pi)
            let degrees: Float
            if rawDegrees.sign == .minus {
                degrees = rawDegrees + 360
            } else {
                degrees = rawDegrees
            }
            let turns = degrees / 360 // 1 turn = 360• = π
//            let byteRange = (UInt8.min..<UInt8.max)
            let scaledTurns = (turns * 255.0).rounded()
//            if scaledTurns > 255.0 {
//                scaledTurns = 255.0
//            }
            let rot: UInt8 = min(UInt8.max, max(UInt8.min, UInt8(scaledTurns)))
            try c.encode(rot)

            try c.encode(UInt8(0x0)) // pad
            try c.encode(UInt16(0x0)) // target id
            try c.encode(sequence: [UInt8](repeating: .zero, count: 5))
        }
    }
}
