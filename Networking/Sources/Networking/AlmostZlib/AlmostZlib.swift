//
//  AlmostZlib.swift
//  
//
//  Created by kuluu-jon on 5/26/22.
//

import Foundation
import BinaryCodable

public extension Data {
    
    private func load<U>(offset: Int, as type: U.Type) -> U where U: BinaryInteger {
        withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            
            var storage: U = .init()
            let value: U = withUnsafeMutablePointer(to: &storage) {
                $0.deinitialize(count: 1)
                
                guard buffer.count >= MemoryLayout<U>.size,
                      let source:UnsafeRawPointer = buffer.baseAddress.map(UnsafeRawPointer.init(_:))
                else
                {
                    fatalError("attempt to load \(U.self) from buffer of size \(buffer.count)")
                }
                
                let raw: UnsafeMutableRawPointer = .init($0)
                raw.copyMemory(from: source, byteCount: MemoryLayout<U>.size)
                
                return raw.load(fromByteOffset: offset, as: U.self)
            }
            
            return U(value)
        }
    }
    
    func toUInt16(offset: Int = 0) -> UInt16 {
        load(offset: offset, as: UInt16.self)
//        withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt16.self) }
    }
//
    func toUInt32(offset: Int = 0) -> UInt32 {
        load(offset: offset, as: UInt32.self)

//        withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
    }
//
    func toInt32(offset: Int = 0) -> Int32 {
        load(offset: offset, as: Int32.self)
//        withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
    }
//
    func toUInt(offset: Int = 0) -> UInt {
        load(offset: offset, as: UInt.self)
//        withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt.self) }
    }
}

public class z {
    public struct Jump: BinaryDecodable {
        var ptr: UInt32
        public init(from decoder: BinaryDecoder) throws {
            var c = decoder.container(maxLength: 4)
            ptr = try c.decode(UInt32.self)
        }
    }
    public var jumps: [UInt32]
    
    // TODO: optimize me
    init() async {
        let decs = await jumpTable.chunked(into: 4).map { $0.toUInt32() }
        let u4 = UInt32(4)
        // Base address of dec table, if we substract pointer in dec table, we should should be
        // able to normalize them to offsets starting from 0.
        let baseslot = decs[0] - UInt32(4)
        var jumps = [UInt32]()
        for dec in decs {
            if dec > 0xFF {
                
                // Everything over 0xff are pointers.
                // These pointers will be traversed until we hit data.
                jumps.append((dec &- baseslot) / u4)

            } else {
                
                // Everything equal or less to 0xff is 8bit data.
                // The pointers at offsets -3 and -2 in table must be zero for each non-zero data entry
                // This approach assumes pointers are at least 8bit on the system.
                jumps.append(dec)
//                assert(jumps.last == 0 || jumps.count < 3 || (jumps[jumps.count - 2] == 0 && jumps[jumps.count - 3] == 0));

            }
        }
        self.jumps = jumps
    }
    
    func decompress(data inData: Data, maxSize: Int) -> Data {
        assert(!jumps.isEmpty)
        var jmp = jumps.first!
//        guard inData.first == 1 else {
//            fatalError("invalid compressed data")
//        }
//        byte[] buffer = new byte[(int)Math.Ceiling(packetsize / 8m)];
        let thing = min(inData.count, 1400) //Int((Double(inData.count)/8.0).rounded(.up))
        let buffer = Data(inData[1..<Int(thing)])
        var w = 0
        var out = Data.init(capacity: IncomingPacket.maxLength)
        for i in 0..<thing where w < IncomingPacket.maxLength {
            let s0 = buffer[i / 8]
            let s = ((s0 >> (i & 7)) & 1)
            let needJump = s == 1
            jmp = jumps[Int(jmp) + Int(s)]
            if jumps[Int(jmp)] != 0 || jumps[Int(jmp) + 1] != 0 {
                continue // keep following
            } else {
                let realData = jumps[Int(jmp) + 3]
                assert(realData <= 0xFF)
                out.append(contentsOf: realData.bytes)//.insert(contentsOf: realData.bytes, at: w)
                w += 1
            }
                //                            continue
                //                        }
//            if needJump {
//                continue
//            } else {
//
//            }
        }
        return out
    }
    
    func decompress2(data inData: Data, maxSize: Int) -> Data {
        
//        let zlibPacketSize = Int(data.toUInt32(offset: data.endIndex - 20))
//        let zlibBufferSize = Int((Double(zlibPacketSize) / Double(chunkSize)).rounded(.up))
        let start = 0
//        let end = start + zlibBufferSize
//        print("zlibPacketSize", zlibPacketSize)
        let zlibBuffer = inData[start..<maxSize]
        var outbuf: Data = .init()
        let chunkSize = 8

        var pos = jumps.first!
        var savedBytes = 0
//                    decompress(data)
        for i in 0..<maxSize where outbuf.count < IncomingPacket.maxLength {
            let s = ((zlibBuffer[i / chunkSize] >> (i & chunkSize - 1)) & 1)
            pos = jumps[Int(pos) + Int(s)]
            if s > 0 {
                savedBytes += 1
            }
            let intPos = Int(pos)
            if jumps[intPos] != 0 || jumps[intPos + 1] != 0 {
                continue
            }
            outbuf.append(jumps[intPos + 3].bytes.first!)
            pos = jumps[0]
        }
        return outbuf
    }
    
//        uint32      w    = 0;
//        const int8* data = in + 1;
//        for (uint32 i = 0; i < in_sz && w < out_sz; ++i)
//        {
//            jmp = static_cast<const struct zlib_jump*>(jmp[JMPBIT(data, i)].ptr);
//            assert(jmp >= zlib.jump.data() && jmp <= zlib.jump.data() + zlib.jump.size());
//
//            // Repeat until there is nowhere to jump to
//            if (jmp[0].ptr != nullptr || jmp[1].ptr != nullptr)
//            {
//                continue;
//            }
//
//            // The remaining address should be data
//            assert(jmp[3].ptr <= reinterpret_cast<void*>(0xff));
//            out[w++] = static_cast<uint8>(reinterpret_cast<std::uintptr_t>(jmp[3].ptr));
//            jmp      = static_cast<const struct zlib_jump*>(zlib.jump[0].ptr);
//
//            if (w >= out_sz)
//            {
//                ShowWarning("zlib_decompress: ran out of space (%u : %u)", in_sz, out_sz);
//                return -1;
//            }
//        }
//
//        return w;
//    }

}
