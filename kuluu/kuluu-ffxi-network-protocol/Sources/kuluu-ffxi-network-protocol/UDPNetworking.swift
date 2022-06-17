import CocoaAsyncSocket
import CryptoSwift
import BinaryCodable
import CFNetwork
import Foundation
import Combine
import CollectionConcurrencyKit

/// Swift `async` wrapper and syntactic sugar for GCDAsyncUdpSocket
public actor UDPNetworking {
    enum ConnectError: Error {
        case noAddressReturned
    }
    
    enum SendError: Error {
        case sendFailed(tag: Int)
    }
    
    enum ReceiveError: Error {
        case receiveBufferTooSmall(Int)
    }
    
    private let socket: GCDAsyncUdpSocket
    private let delegate = UdpSocketDelegate()
    private let delegateQueue = DispatchQueue(label: "UDPSocketDelegateQueue")
    private let socketQueue = DispatchQueue(label: "UDPSocketQueue")
    let host: String
    let port: UInt16
    private let timeout: TimeInterval
    private let blowfish: Blowfish?
    private(set) var sendCount: Int = 0
    
    public init(host: String = "127.0.0.1", port: UInt16 = 54231, clientVersion: String = "30181250_0", timeout: TimeInterval = 60.0, blowfish: Blowfish? = defaultBlowfish) {
        self.host = host
        self.port = port
        self.timeout = timeout
        self.blowfish = blowfish
        
        socket = .init(delegate: delegate, delegateQueue: delegateQueue, socketQueue: socketQueue)
        socket.setMaxReceiveIPv4BufferSize(4096)
        socket.setMaxReceiveIPv6BufferSize(4096)
    }
    
    deinit {
        close()
    }
    
    private var connectCancellable: AnyCancellable?
    private var sendCancellable: AnyCancellable?

    public func connect() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                delegate.didConnect = nil
                connectCancellable = delegate.$didConnect
                    .filter { $0 != nil }
                    .first()
                    .sink(receiveValue: { result in
                        if case .success(let address) = result {
                            if let host = GCDAsyncSocket.host(fromAddress: address) {
                                print(self.delegate.logId, "connected to host:", host)
                            }
                            continuation.resume()
                        } else if case .failure(let error) = result {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(throwing: ConnectError.noAddressReturned)
                        }
                    })
                try socket.connect(toHost: host, onPort: port)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    public func send<Packet>(packet: AttachHeaderAndMD5Footer<Packet>, encoder: BinaryDataEncoder = .init()) async throws {
//        let skipEncryption = !packet.packet.isBodyEncrypted
        
        let outputData: Data
        if packet.packet.isBodyEncrypted {
//            let start = packet.packet.start(packetType: packet.packet.id, size: packet.packet.size)
            let packetBody = try encoder.encode(packet)
            outputData = Data(try defaultBlowfish.encrypt(packetBody))
//            outputData = Data(try defaultBlowfish.encrypt(start + packetBody))
        } else {
            outputData = try encoder.encode(packet)
            assert(outputData.count > 28 + 16)
            let check = outputData.suffix(16)
            let toMd5 = outputData[28..<outputData.count-16]
            let md5 = toMd5.md5()
            assert(md5.elementsEqual(check))
        }
        
//        let body = try encoder.encode(packet.packet)
//        let header = try encoder.encode(packet.packet.header)
//        let encryptedPacket: [UInt8]? = !skipEncryption ? try blowfish?.encrypt(encryptionInput) : nil
//        var output: [UInt8] = header.bytes
//        output.append(contentsOf: encryptedPacket ?? encryptionInput.bytes)
//        output.append(contentsOf: packet.md5)
//        let outputData = Data(packet)
        print(delegate.logId, "willSendDataWithTag:", "{\n\ttag:", sendCount, "\n\toutPacket", outputData.toHexString(), "\n\tmd5:", packet.md5.toHexString(), "\n}")

//        print(delegate.logId, "willSendDataWithTag:", "{\n\ttag:", sendCount, "\n\theader:", header.toHexString(), "\n\tbody:", body.toHexString(), "\n\toutPacket", outputData.toHexString(), "\n\tmd5:", packet.md5.toHexString(), "\n}")
        let thisSendCount = sendCount
        sendCount += 1
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delegate.didSend = nil
            sendCancellable = delegate.$didSend
                .first(where: { result in
                    if case .success(let tag) = result {
                        return tag == thisSendCount
                    } else if case .failure(let error) = result, case SendError.sendFailed(let tag) = error {
                        return tag == thisSendCount
                    } else {
                        return false
                    }
                })
                .sink(receiveValue: { result in
                    if case .success = result {
                        continuation.resume()
                    } else if case .failure(let error) = result {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ConnectError.noAddressReturned)
                    }
                })
            socket.send(outputData, withTimeout: timeout, tag: thisSendCount)
        }
    }
    public func send(data: Data, tryEncryption: Bool = true) async throws {
        let encryptedBytes: [UInt8]? = tryEncryption ? try blowfish?.encrypt(data.bytes) : nil
//        let encryptedBytes: Data? = nil
        let encryedData: Data? = encryptedBytes != nil ? Data(encryptedBytes!) : nil
        print(delegate.logId, "willSendDataWithTag:", "{\n\ttag:", sendCount, "\n\thex:", data.toHexString(), "\n\tencyptedHex", encryedData?.toHexString() ?? "N/A","\n}")
        let thisSendCount = sendCount
        sendCount += 1
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delegate.didSend = nil
            sendCancellable = delegate.$didSend
                .first(where: { result in
                    if case .success(let tag) = result {
                        return tag == thisSendCount
                    } else if case .failure(let error) = result, case SendError.sendFailed(let tag) = error {
                        return tag == thisSendCount
                    } else {
                        return false
                    }
                })
                .sink(receiveValue: { result in
                    if case .success = result {
                        continuation.resume()
                    } else if case .failure(let error) = result {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ConnectError.noAddressReturned)
                    }
                })
            socket.send(encryedData ?? data, withTimeout: timeout, tag: thisSendCount)
        }
//        try socket.receiveOnce()
    }
    
    public func beginReceiving() throws -> AnyPublisher<Data, Error> {
        try socket.beginReceiving()
        return delegate.$didReceive
            .receive(on: self.delegateQueue)
            .compactMap { $0 }
            .tryMap { (result: Result<Data, Error>) -> Data in
                switch result {
                case .success(let data):
                    guard data.count >= 28 + 16 else {
                        throw ReceiveError.receiveBufferTooSmall(data.count)
                    }
//                    let header = data.prefix(28)
//                    let md5 = data.suffix(16)
                    // pad to be multiple of 8 length
//                    let encryptedBytes = data[8..<data.count]
                    
                    
//                    let decryptedBytes = try self.blowfish?.decrypt(encryptedBytes) ?? encryptedBytes
                    return data
                case .failure(let error):
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
    
//    public func receiveOnce(tag: UInt16) async throws -> (Data, Int) {
//        let thisSendCount = tag
//        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, Int), Error>) in
//            delegate.didSend = nil
//            sendCancellable = delegate.$didReceive
//                .first(where: { result in
//                    if case .success(let tuple) = result {
//                        return tuple.1 == thisSendCount
//                    } else if case .failure(let error) = result, case SendError.sendFailed(let tag) = error {
//                        return tag == thisSendCount
//                    } else {
//                        return false
//                    }
//                })
//                .sink(receiveValue: { result in
//                    if case .success(let tuple) = result {
//                        continuation.resume(returning: tuple)
//                    } else if case .failure(let error) = result {
//                        continuation.resume(throwing: error)
//                    } else {
//                        continuation.resume(throwing: ConnectError.noAddressReturned)
//                    }
//                })
//            try? socket.receiveOnce()
////            socket.send(encryedData ?? data, withTimeout: timeout, tag: thisSendCount)
//        }
//
//    }
    
    public func close() {
        socket.close()
    }
}
