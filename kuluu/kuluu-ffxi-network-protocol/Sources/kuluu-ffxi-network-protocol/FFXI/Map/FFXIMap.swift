//
//  File.swift
//  
//
//  Created by kuluu-jon on 5/8/22.
//

import BinaryCodable
import Darwin
import Foundation
import CryptoSwift
import Combine
import CollectionConcurrencyKit
import Compression

public protocol ProvidesMap: ProvidesMapBase, ProvidesMapLogin, ProvidesMapChat, ProvidesMapMovement {
}

public protocol ProvidesMapBase {
    func connect() async throws
}

extension Data {
    func chunked(into size: Int, isPadded: Bool = true) async -> [Data] {
        let copySelf = Data(self)
        return await stride(from: 0, to: count, by: size).asyncMap { index -> Data? in

            guard count >= size, copySelf.indices.contains(index) else {
                return nil
            }

            var data = copySelf[index ..< Swift.min(index + size, count)]
            let remainder = data.count % size
            if isPadded, remainder > 0 {
                let zeros: [UInt8] = .init(repeating: 0, count: size - remainder)
                data.append(contentsOf: zeros)
            }
            return data
        }.compactMap { $0 }
    }
}

public actor FFXIMap: ProvidesMap {
    private let character: AccountResponse.CharacterSlot
    private let mapNet: UDPNetworking
    private let searchNet: UDPNetworking

    private let decoder = BinaryDataDecoder()
    private let encoder = BinaryDataEncoder()
    private var sendCount: UInt16 = 2 // to match hxiclient.py

    private var receivingCancellable: AnyCancellable? {
        didSet {
            oldValue?.cancel()
        }
    }

    public init(character: AccountResponse.CharacterSlot, mapNet: UDPNetworking, searchNet: UDPNetworking) {
        self.character = character
        self.mapNet = mapNet
        self.searchNet = searchNet

    }

    public func connect() async throws {

//        func createChunks(ofSize chunkSize: Int, from data: Data) {
//
//            data.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
//                let mutRawPointer = UnsafeMutableRawPointer(mutating: u8Ptr)
//                let totalSize = data.count
//                var offset = 0
//
//                while offset < totalSize {
//                    let chunkSize = offset + chunkSize > totalSize ? totalSize - offset : chunkSize
//                    let chunk = Data(bytesNoCopy: mutRawPointer+offset, count: chunkSize, deallocator: Data.Deallocator.none)
//                    offset += chunkSize
//                }
//            }
//        }

        try await mapNet.connect()
        let z = await z.init()
        receivingCancellable = try await mapNet.beginReceiving()
            .print()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    assertionFailure(error.localizedDescription)
                }
            }, receiveValue: { data in

                let id = UUID().uuidString
                Task.detached(priority: .background) {
                    print("header", data.prefix(min(28, data.count)).toHexString())
                    print("body", data.suffix(data.count - 28).toHexString())
                    let incomingPacket = try self.decoder.decode(IncomingPacket.self, from: data)
                    print(incomingPacket)
                    var data = incomingPacket.encryptedBody
                    let checksum = incomingPacket.md5

                    guard !Task.isCancelled else { return }

                    let remainder = data.count % Blowfish.blockSize

                    if remainder > 0 {
                        let zeros: [UInt8] = .init(repeating: 0, count: Blowfish.blockSize - remainder)
                        data.append(contentsOf: zeros)
                    }

//                    let chunked = await data.chunked(into: chunkSize)
//
//                    print(chunked.map { $0.toHexString() })
                    guard !Task.isCancelled else { return }
//                    let decryptedChunks = try? chunked.map { encryptedBytes -> Data in
//                        assert(encryptedBytes.bytes.count == chunkSize)
//                        let decryptedBytes = try defaultBlowfish.decrypt(encryptedBytes)
//                        return Data(decryptedBytes)
//                    }

                    let d = try! defaultBlowfish.decrypt(data.bytes)

                    guard !Task.isCancelled else { return }
//                    guard let d = decryptedChunks?.joined() else {
//                        fatalError("hey")
//                    }
                    let decrypted = Data(d)
//                    print("encrypted", data.toHexString())
//                    data = Data(decrypted)
                    print("decrypted+compressed", decrypted.toHexString())
//                    let zlibPacketSize = Int(decrypted.toUInt32(offset: decrypted.endIndex - 4))
//                    let zlibBufferSize = Int(Double(zlibPacketSize))

                    let zlibPacketSize = Int(decrypted.toUInt32(offset: decrypted.endIndex - 20))
                    let zlibBufferSize = Int((Double(zlibPacketSize) / Double(Blowfish.blockSize)).rounded(.up))
                    let decompressed = z.decompress(data: decrypted, maxSize: zlibPacketSize)
//                    let decompressed = try? NSData.init(data: data).decompressed(using: .zlib)
                    print("decompressed", decompressed.toHexString())
                    print("checksum", checksum.toHexString())
                    let md5 = decompressed.md5()
                    print("equals? ", md5.toHexString())
//                    assert(checksum == md5)
////                    let md5 = data[headerSize..<16]
//                    let zlibPacketSize = Int(data.toUInt32(offset: data.endIndex - 20))
//                    let zlibBufferSize = Int((Double(zlibPacketSize) / Double(chunkSize)).rounded(.up))
//                    let start = 0
//                    let end = start + zlibBufferSize
//                    print("zlibPacketSize", zlibPacketSize)
//                    let zlibBuffer = data[start..<end]
//                    var outbuf: Data = .init()
//
//                    var pos = z.jumps.first!
//                    var savedBytes = 0
////                    decompress(data)
//                    for i in 0..<zlibPacketSize where outbuf.count < IncomingPacket.maxLength {
//                        let s = ((zlibBuffer[i / chunkSize] >> (i & chunkSize - 1)) & 1)
//                        pos = z.jumps[Int(pos) + Int(s)]
//                        if s > 0 {
//                            savedBytes += 1
//                        }
//                        let intPos = Int(pos)
//                        if z.jumps[intPos] != 0 || z.jumps[intPos + 1] != 0 {
//                            continue
//                        }
//                        outbuf.append(z.jumps[intPos + 3].bytes.first!)
//                        pos = z.jumps[0]
//                    }
//                    print("decompressed", outbuf.toHexString())
//                    print("...from \(data.count) to \(outbuf.count), zlibPacketSize: \(zlibPacketSize), jumped: \(savedBytes) times")
//                    let packetBody = outbuf
                    let size = decompressed.count > 2 ? decompressed[1] & 0x0FE : 0
                    var index = 0
                    while index < decompressed.count, decompressed.count - index > 2, size > 0 {
                        let typeBytes = decompressed[index..<index+2]
                        let type = typeBytes.toUInt16() & 0x1FF
                        let size = typeBytes.last! & 0x0FE

                        index += Int(size) * 2
                        print("\(id.prefix(3)) !!!!PACKET!!!!! {type:\(String(format: "%02X", type)), size: \(size)}")
                    }
//                    int index = 0;
//                    int size = final.Length > 2 ? final[index + 1] & 0x0FE : 0;
//                    while (index < final.Length && final.Length - index > 2 && size > 0)
//                    {
//                        int type = BitConverter.ToUInt16(final, index) & 0x1FF;
//                        size = final[index + 1] & 0x0FE;
//                        //
//                        switch (type)
//                        {
//                        case 0x08://Zones Visited
//                        case 0x0D://Char
//                        case 0x0E://EntityUpdate
//                        case 0x1D://InventoryFinish
//                        case 0x1F://InventoryAssign
//                        case 0x20://Inventory Item
//                        case 0x28://Action
//                        case 0x41://Blacklist//Stopdownloading data
//                        case 0x44://Job Extra
//                        case 0x4f://Downloading Data
//                        case 0x51://Char Appearance
//                        case 0x55://KeyItems
//                        case 0x56://QuestMissionLog
//                        case 0x5E://Conquest
//                        case 0x61://CharStats
//                        case 0x62://CharSkills
//                        case 0x63://MenuMerit
//                        case 0x67://Char Sync
//                        case 0x71://Campaign
//                        case 0x8C://MeritPointCategories
//                        case 0xAA://SpellList
//                        case 0xAC://CharAbilites
//                        case 0xAE://CharMounts
//                        case 0xB4://MenuConfigFlags
//                        case 0xCA://BazaarMessage
//                        case 0xD2://TreasureFindItem
//                        case 0x119://CharRecast
//                            break;
//                        case 0x0A:
//                            P00A(final, size, index);//Zone In
//                            break;
//                        case 0x17:
//                            P017(final, size, index);//Chat Messagae
//                            break;
//                        case 0x1B:
//                            P01B(final, size, index);
//                            break;
//                        case 0x1C://Inventory Size
//                            P01C(final, size, index);
//                            break;
//                        case 0x37://Char Update
//                            P037(final, size, index);
//                            break;
//                        case 0x4D://ServerMessage
//                            P04D(final, size, index);
//                            break;
//                        case 0x50://Equipment
//                            P050(final, size, index);
//                            break;
//                        case 0xDF:
//                            P0DF(final, size, index);//Char/trust Health
//                            break;
//                        default:
//                            if (!silient)
//                                Console.WriteLine("Received packet:{0:X}: Size:{1:X}", type, size);
//                            break;
//
//                        }
//                        index += size * 2;
//                    }

//
//                        pos = myzlib.jump[pos + s];
//                        //Console.WriteLine("{0:G} : {1:G}  0,1 {2:G},{3:G}", s, pos, myzlib.jump[pos], myzlib.jump[pos+1]);
//                        if (myzlib.jump[pos] != 0 || myzlib.jump[pos + 1] != 0)
//                        {
//                            //Console.WriteLine("Pos:{0:G} not both zero", pos);
//                            continue;
//                        }
//                        //Console.WriteLine("DATA:{0:G}", myzlib.jump[pos + 3]);
//                        outbuf[w++] = BitConverter.GetBytes(myzlib.jump[pos + 3])[0];
//                        //Console.WriteLine(BitConverter.GetBytes(myzlib.jump[pos + 3])[0]);
//                        pos = myzlib.jump[0];
//                    }
//                    byte[] final = new byte[w];
//                    System.Buffer.BlockCopy(outbuf, 0, final, 0, w);
//                    //Console.WriteLine("Dezlib size:" +final.Length+ "\n" + BitConverter.ToString(final).Replace("-", " "));
//                    int index = 0;
//                    int size = final.Length > 2 ? final[index + 1] & 0x0FE : 0;

//                    let eightByteSegmentCount = (Double(body.count) / 8.0).rounded(.up)
//                    let bytesToPad = body.count % 8
//
//                    if bytesToPad > 0 {
////                        let zeros = [UInt8] = .init(repeating: 0, count: bytesToPad)
//                        // whatever.append(contentsOf: zeros)
//                    }
                }

            })
    }

}

// MARK: Login

public extension FFXIMap {
    func zoneIn() async throws {

        guard let p1 = try FFXIMapPacket.StartZoneTransition(sendCount: sendCount, characterId: character.id).packed(encoder: encoder, skipStart: true) else {
            fatalError("nil!")
        }
        try await mapNet.send(packet: p1)
        sendCount += 1

        guard let p2 = try FFXIMapPacket.ZoneTransitionConfirmation(sendCount: sendCount).packed(encoder: encoder, skipStart: true) else {
            fatalError("nil!")
        }
        try await mapNet.send(packet: p2)
        sendCount += 1
//        sleep(1)
        guard let p3 = try FFXIMapPacket.CharacterInformationRequest(sendCount: sendCount).packed(encoder: encoder, skipStart: true) else {
            fatalError()
        }
        try await mapNet.send(packet: p3)
        sendCount += 1
    }

    func logout() async throws {

    }
}

// MARK: Chat

public extension FFXIMap {
    func send(chatMessage: String) async throws {
        guard let p1 = try FFXIMapPacket.SendChat.init(sendCount: sendCount, type: 0, message: chatMessage).packed(encoder: encoder) else {
            return
        }
        try await mapNet.send(packet: p1)
        sendCount += 1
    }
}

public extension FFXIMap {
    func sync(position: SIMD3<Float>, rotation: Float) async throws {
        guard let p1 = try FFXIMapPacket.PlayerSyncRequest(
            sendCount: sendCount,
            position: position,
            rotation: rotation,
            targetId: 0
        ).packed(encoder: encoder) else { return }
        try await mapNet.send(packet: p1)
        sendCount += 1
    }
}
