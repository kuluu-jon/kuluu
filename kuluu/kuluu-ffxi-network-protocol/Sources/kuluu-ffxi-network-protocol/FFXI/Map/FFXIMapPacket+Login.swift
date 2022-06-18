//
//  FFXIMapPacket+Login.swift
//  
//
//  Created by kuluu-jon on 5/9/22.
//

import BinaryCodable

public protocol ProvidesMapLogin {
    // login
    func zoneIn() async throws
    func logout() async throws // same as `/logout`
}

// MARK: Client -> Server

public extension FFXIMapPacket {

//    startingkey[4] += 2;
//    byte[] byteArray = new byte[startingkey.Length * 4];
//    Buffer.BlockCopy(startingkey, 0, byteArray, 0, startingkey.Length * 4);
//    //Console.WriteLine("[Info]Blowfish key:" + BitConverter.ToString(byteArray).Replace("-", "").TrimStart('0'));
//    byte[] hashkey;
//    hashkey = hasher.ComputeHash(byteArray);
//    for (int i = 0; i < 16; ++i)
//    {
//        if (hashkey[i] == 0)
//        {
//            byte[] zero = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
//            System.Buffer.BlockCopy(zero, i, hashkey, i, 16 - i);
//        }
//    }
//    //Console.WriteLine("[Info]Blowfish hash:" + BitConverter.ToString(hashkey).Replace("-", " "));
//    tpzblowfish = new Blowfish();
//    tpzblowfish.Init(hashkey, 16);
    struct StartZoneTransition: FFXIPacket {

        public var header: EmptyPacketHeader {
            .init(sendCount: sendCount)
        }

        public let id: UInt16 = 0x0A
        public let size: UInt8 = 0x2E
        public let isBodyEncrypted: Bool = false
        public let sendCount: UInt16
        let characterId: UInt32
        public func encode(to encoder: BinaryEncoder) throws {
            var c = encoder.container()
            let zero = UInt8(0)
            try c.encode(UInt8(id))
            try c.encode(size)
            try c.encode(sendCount)
            let pad2: [UInt8] = .init(repeating: zero, count: 0xC - 4)
            try c.encode(sequence: pad2)
            try c.encode(characterId)
            let packetSize = (2 + /*pad1.count + */2 + 2 + pad2.count + 4)
            let origSize = 0x88

            let remaining = max(0, origSize - headerRange.startIndex + 1 - packetSize)
            let pad3: [UInt8] = .init(repeating: zero, count: remaining)
            try c.encode(sequence: pad3)
        }
    }

    struct ZoneTransitionConfirmation: FFXIPacket {

        public var header: EmptyPacketHeader {
            return .init(sendCount: sendCount)
        }
        public let id: UInt16 = 0x11
        public let size: UInt8 = 0x04
        public let sendCount: UInt16
        public let isBodyEncrypted: Bool = false

        public func encode(to encoder: BinaryEncoder) throws {
            // this one is weird and this took me forever to translate from python lol
            var c = encoder.container()
            try c.encode(id)
            try c.encode(size)
            try c.encode(UInt16(0)) // ???
            let zero = UInt8(0)
            let pad1: [UInt8] = .init(repeating: zero, count: Int(size))
            try c.encode(sequence: pad1)
        }
    }

    struct CharacterInformationRequest: FFXIPacket {
        public var header: EmptyPacketHeader {
            .init(sendCount: sendCount)
        }
        public let id: UInt16 = 0xC
        public let size: UInt8 = 0x6
        public let isBodyEncrypted: Bool = false
        public let sendCount: UInt16

        public func encode(to encoder: BinaryEncoder) throws {
            var c = encoder.container()

            // multiple packets all sent in one is a thing

            func pack(packetType: UInt16, size: UInt8) -> [UInt8] {
                var bytes = UInt16(packetType).bytes
                bytes[1] = size
                return bytes
            }

            let zero = UInt8.zero
            try c.encode(sequence: pack(packetType: id, size: size))
            try c.encode(sendCount)
            try c.encode(sequence: [UInt8](repeating: zero, count: 0xA))

            try c.encode(sequence: pack(packetType: 0x61, size: 0x4))
            try c.encode(sendCount)
            try c.encode(sequence: [UInt8](repeating: zero, count: 0x5))

            try c.encode(sequence: pack(packetType: 0x1A, size: 0xE))
            try c.encode(sendCount)
            try c.encode(sequence: [UInt8](repeating: zero, count: 0x7))
            try c.encode(UInt8(0x14)) // action type
            try c.encode(sequence: [UInt8](repeating: zero, count: 0x11))

            try c.encode(sequence: pack(packetType: 0x4B, size: 0xC))
            try c.encode(sendCount)
            try c.encode(sequence: [UInt8](repeating: zero, count: 0x4))
            try c.encode(sequence: [0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8]) // Language,Timestamp,Lengh,Start offset
            try c.encode(sequence: [UInt8](repeating: zero, count: 0x8))

            try c.encode(sequence: pack(packetType: 0xF, size: 0x12))
            try c.encode(sendCount)
            try c.encode(sequence: [UInt8](repeating: zero, count: 0x21))

            // not sent?
//            try c.encode(pack(packetType: 0xDB, size: 0x14))
//            try c.encode(sendCount)
//            try c.encode([UInt8](repeating: zero, count: 0x9))
//            try c.encode(UInt8(0x02)) // language
//            try c.encode([UInt8](repeating: zero, count: 0xC))

            try c.encode(sequence: pack(packetType: 0x5A, size: 0x2))
            try c.encode(sendCount)
            try c.encode(sequence: [UInt8](repeating: zero, count: 0x1))
        }
    }

//    #region RequestCharInfo
//    if (chardata)
//    {
//        data = new byte[183];
//        input = BitConverter.GetBytes(PDcode); //Packet count
//        System.Buffer.BlockCopy(input, 0, data, 0, input.Length);
//
//        input = BitConverter.GetBytes(((UInt16)0x0C)); //Packet type
//        System.Buffer.BlockCopy(input, 0, data, Packet_Head, input.Length);
//        input = new byte[] { 0x06 }; //Size
//        System.Buffer.BlockCopy(input, 0, data, Packet_Head + 0x01, input.Length);
//        input = BitConverter.GetBytes(PDcode); //Packet count
//        System.Buffer.BlockCopy(input, 0, data, Packet_Head + 0x02, input.Length);
//        int new_Head = Packet_Head + (0x06 * 2);
//
//        input = BitConverter.GetBytes(((UInt16)0x61)); //Packet type
//        System.Buffer.BlockCopy(input, 0, data, new_Head, input.Length);
//        input = new byte[] { 0x04 }; //Size
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x01, input.Length);
//        input = BitConverter.GetBytes(PDcode); //Packet count
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x02, input.Length);
//        new_Head = new_Head + (0x04 * 2);
//
//        input = BitConverter.GetBytes(((UInt16)0x01A)); //Packet type
//        System.Buffer.BlockCopy(input, 0, data, new_Head, input.Length);
//        input = new byte[] { 0x0E }; //Size
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x01, input.Length);
//        input = BitConverter.GetBytes(PDcode); //Packet count
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x02, input.Length);
//        input = new byte[] { 0x14 }; //Action type
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x0A, input.Length);
//        new_Head = new_Head + (0x0E * 2);
//
//        input = BitConverter.GetBytes(((UInt16)0x4B)); //Packet type
//        System.Buffer.BlockCopy(input, 0, data, new_Head, input.Length);
//        input = new byte[] { 0x0C }; //Size
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x01, input.Length);
//        input = BitConverter.GetBytes(PDcode); //Packet count
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x02, input.Length);
//        input = new byte[] { 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }; //Language,Timestamp,Lengh,Start offset
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x07, input.Length);
//        new_Head = new_Head + (0x0C * 2);
//
//        input = BitConverter.GetBytes(((UInt16)0x0F)); //Packet type
//        System.Buffer.BlockCopy(input, 0, data, new_Head, input.Length);
//        input = new byte[] { 0x12 }; //Size
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x01, input.Length);
//        input = BitConverter.GetBytes(PDcode); //Packet count
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x02, input.Length);
//        new_Head = new_Head + (0x12 * 2);
//
//        //input = BitConverter.GetBytes(((UInt16)0x0DB)); //Packet type
//        //System.Buffer.BlockCopy(input, 0, data, new_Head, input.Length);
//        //input = new byte[] { 0x14 }; //Size
//        //System.Buffer.BlockCopy(input, 0, data, new_Head + 0x01, input.Length);
//        //input = BitConverter.GetBytes(PDcode); //Packet count
//        //System.Buffer.BlockCopy(input, 0, data, new_Head + 0x02, input.Length);
//        //input = new byte[] { 0x02 }; //Language
//        //System.Buffer.BlockCopy(input, 0, data, new_Head + 0x24, input.Length);
//        //new_Head = new_Head + (0x14 * 2);
//
//        input = BitConverter.GetBytes(((UInt16)0x5A)); //Packet type
//        System.Buffer.BlockCopy(input, 0, data, new_Head, input.Length);
//        input = new byte[] { 0x02 }; //Size
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x01, input.Length);
//        input = BitConverter.GetBytes(PDcode); //Packet count
//        System.Buffer.BlockCopy(input, 0, data, new_Head + 0x02, input.Length);
//        new_Head = new_Head + (0x02 * 2);
//
//        packet_addmd5(ref data);
//        if (!silient)
//            Console.WriteLine("[Game]Outgoing packet multi,Sending Post zone data requests");
//        Gameserver.Send(data, data.Length);
//        PDcode++;
//    }
//    #endregion
}

// MARK: Server -> Client

public extension FFXIMapPacket {
//    struct StartZoneTransition: FFXIPacket {
//        public var header: CompletelyEmptyPacketHeader {
//            .init(sendCount: 0)
//        }
//    }
}
