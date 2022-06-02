//
//  File.swift
//  
//
//  Created by kuluu-jon on 5/9/22.
//

import Foundation
import BinaryCodable

public protocol ProvidesMapChat {
    // chat
    func send(chatMessage: String) async throws
}

// MARK: Client -> Server

public extension FFXIMapPacket {
    
    struct SendChat: FFXIPacket {
        
        enum Error: Swift.Error {
            case messageMaxLengthExceeded(length: Int, max: UInt8)
        }
        
        public var header: EmptyPacketHeader {
            .init(sendCount: sendCount)
        }
        
        public let id: UInt16 = 0x00B5
        public let sendCount: UInt16
        public var size: UInt8 = 130
        public let isBodyEncrypted: Bool = true
        let type: UInt8
        let message: String
        
        public func encode(to encoder: BinaryEncoder) throws {
            var c = encoder.container()
            let maxPacketLength = size
            guard message.count < 124 else { // todo: it is less than this?
                throw Error.messageMaxLengthExceeded(length: message.count, max: size)
            }
            let zero = UInt8.zero
            let pad1: [UInt8] = .init(repeating: zero, count: 4)
            try c.encode(sequence: pad1)
            try c.encode(type)
            try c.encode(zero)
            try c.encode(message, encoding: .ascii, terminator: nil)
            
            let remaining = max(0, Int(maxPacketLength) - 4 + 1 + 1 + message.count)
            let pad2: [UInt8] = .init(repeating: zero, count: remaining)
            try c.encode(sequence: pad2)
        }
    }
}

// MARK: Server -> Client

public extension FFXIMapPacket {
    
}
