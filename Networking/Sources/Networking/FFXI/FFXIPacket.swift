//
//  FFXIPacket.swift
//  
//
//  Created by kuluu-jon on 5/8/22.
//

import Foundation
import BinaryCodable

struct IncomingHeader: BinaryCodable, CustomStringConvertible {
    
    static let size = 28
    let serverPacketId: UInt16
    let clientPacketId: UInt16
    let data1: Data
    let packetTime: UInt32
    let data2: Data
    
    init(from decoder: BinaryDecoder) throws {
        var c = decoder.container(maxLength: 28)
        serverPacketId = try c.decode(UInt16.self) // 2
        clientPacketId = try c.decode(UInt16.self) // 4
        data1 = try c.decode(length: 4) // 8
        packetTime = try c.decode(UInt32.self) // 12
        data2 = try c.decode(length: 16) // 28
    }
    
    func encode(to encoder: BinaryEncoder) throws {
        var c = encoder.container()
        try c.encode(serverPacketId)
        try c.encode(clientPacketId)
        try c.encode(sequence: data1)
        try c.encode(packetTime)
        try c.encode(sequence: data2)
    }
    
    var description: String {
        "{\"serverPacketId\": \(serverPacketId), \"clientPacketId\": \(clientPacketId), \"data1\": \(data1.bytes.first!), \"packetTime\": \(packetTime), \"data2\": \(data2.bytes.first!)}"
    }
}

struct IncomingPacket: BinaryCodable, CustomStringConvertible {
    static let maxLength = 1800 // or 1300 - FFXI_HEADER_SIZE - 16
    let header: IncomingHeader
    let encryptedBody: Data
    let md5: Data
    
    init(from decoder: BinaryDecoder) throws {
        var c = decoder.container(maxLength: Self.maxLength)
        header = try c.decode(IncomingHeader.self)
        let remainder = try c.decodeRemainder()
        let remainderLength = remainder.count
        let md5Length = 16
        assert(remainderLength > md5Length)
        encryptedBody = remainder.prefix(remainderLength - md5Length)
        md5 = remainder.suffix(md5Length)
        assert(encryptedBody.count + md5.count == remainder.count)
    }
    
    func encode(to encoder: BinaryEncoder) throws {
        var c = encoder.container()
        try c.encode(header)
        try c.encode(sequence: encryptedBody)
        try c.encode(sequence: md5)
    }
    
    var description: String {
        "{\"header\": \(header), \"encryptedBody\": \(encryptedBody.toHexString().prefix(8)), \"md5\": \(md5.toHexString())}"
    }
}

public let headerRange = (0x2B..<0x3B) //

public struct AttachHeaderAndMD5Footer<Packet: FFXIPacket>: BinaryEncodable {
    public let packet: Packet
    public let skipStart: Bool
    public let md5: Data
    
    public func encode(to encoder: BinaryEncoder) throws {
        var c = encoder.container()
        try c.encode(packet.header)
        if !skipStart {
            try c.encode(sequence: packet.start(packetType: packet.id, size: packet.size))
        }
        try c.encode(packet)
        assert(md5.count == 16)
        try c.encode(sequence: md5)
    }
}

public protocol FFXIPacket: BinaryEncodable {
    associatedtype Header: BinaryEncodable
    var id: UInt16 { get }
    var sendCount: UInt16 { get }
    var size: UInt8 { get }
    var header: Header { get }
    
    var isBodyEncrypted: Bool { get }
    
    func start(packetType: UInt16, size: UInt8) -> Data
    
    func packed(encoder: BinaryDataEncoder, skipStart: Bool) throws -> AttachHeaderAndMD5Footer<Self>?
}

public extension FFXIPacket {
    func start(packetType: UInt16, size: UInt8) -> Data {
        var bytes = UInt16(packetType).bytes
        bytes[1] = size
        return Data(bytes + sendCount.bytes)
    }

    func packed(encoder: BinaryDataEncoder, skipStart: Bool = false) throws -> AttachHeaderAndMD5Footer<Self>? {
        let start = skipStart ? Data() : start(packetType: id, size: size)
        let data = start + (try encoder.encode(self))
        print("md5 len:", data.count)
        print("to_md5:", data.toHexString())
        let md5 = data.md5()
        print("hexdigest:", md5.toHexString())
        return .init(packet: self, skipStart: skipStart, md5: md5)
    }
}

public struct EmptyPacketHeader: BinaryEncodable {
    let sendCount: UInt16
    public func encode(to encoder: BinaryEncoder) throws {
        let zero = UInt8(0)
        var c = encoder.container()
        try c.encode(sendCount)
        let pad1: [UInt8] = .init(repeating: zero, count: 26)
        try c.encode(sequence: pad1)
    }
}
