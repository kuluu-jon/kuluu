//
//  File.swift
//  
//
//  Created by kuluu-jon on 5/6/22.
//

import CocoaAsyncSocket
import CryptoSwift
import CFNetwork
import Foundation
import Combine

public let defaultBlowfish: kuluu_ffxi_network_protocol.Blowfish = {
    // thanks to whoever was smart enough to originally reverse this 15 years ago :)
    let key: [UInt8] = [
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x58, 0xE0, 0x5D, 0xAD
    ]
    var keyHash = MD5().calculate(for: key)
    print("Blowfish Key", key.toHexString())
    print("keyHash", keyHash.toHexString())

//    var firstZeroIndex = 0
//    for i in 0..<16 {
//        if keyHash[i] == 0 {
//            firstZeroIndex = i
//            break
//        }
//    }
//    let zeroOutRange = firstZeroIndex..<keyHash.count
//    keyHash.replaceSubrange(zeroOutRange, with: [UInt8](repeating: .zero, count: zeroOutRange.count))
    return try! .init(key: keyHash, padding: .zeroPadding)

//    return try! .init(key: keyHash.toHexString(), iv: "0000000000000000")
}()

import CryptoKit

/// Swift `async` wrapper and syntactic sugar for GCDAsyncUdpSocket
actor TCPNetworking {
    enum ConnectError: Error {
        case noAddressReturned
    }

    enum SendError: Error {
        case sendFailed(tag: Int)
    }

    private let socket: GCDAsyncSocket
    private weak var delegate = TcpSocketDelegate()
    private let delegateQueue = DispatchQueue(label: "TCPSocketDelegateQueue")
    private let socketQueue = DispatchQueue(label: "TCPSocketQueue")
    let host: String
    let port: UInt16
    private let timeout: TimeInterval
    private let blowfish: Blowfish?
    private(set) var sendCount: Int = 0

    public init(host: String = "127.0.0.1", port: UInt16 = 54231, clientVersion: String = "30181250_0", timeout: TimeInterval = 60.0, blowfish: Blowfish? = nil) {
        self.host = host
        self.port = port
        self.timeout = timeout
        self.blowfish = blowfish

        socket = .init(delegate: delegate, delegateQueue: delegateQueue, socketQueue: socketQueue)
    }

    private var connectCancellable: AnyCancellable?
    private var sendCancellable: AnyCancellable?

    public func connect() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                delegate?.didConnect = nil
                connectCancellable = delegate?.$didConnect
                    .filter { $0 != nil }
                    .first()
                    .sink(receiveValue: { result in
                        if case .success(let address) = result {
//                            if let host = GCDAsyncSocket.host(fromAddress: url.) {
                            print(self.delegate?.logId, "connected to host:", address)
//                            }
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

    /// return: the tag of the data frame that was written, along with data read, if `readLength` > 0
    @discardableResult public func write(data: Data, readLength: UInt? = nil, skipRead: Bool = false) async throws -> (Data, Int)? {
        let encryptedBytes = try blowfish?.encrypt(data.bytes)
        let encryedData: Data? = encryptedBytes != nil ? Data(encryptedBytes!) : nil
        print(delegate?.logId, "willSendDataWithTag:", sendCount, "{\n\thex:", data.toHexString(), "\n\tencyptedHex", encryedData?.toHexString() ?? "N/A", "\n}")
        let thisSendCount = sendCount
        sendCount += 1
        let recv = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, Int), Error>) in
            delegate?.didSend = nil
            sendCancellable = delegate?.$didSend
                .first(where: { result in
                    if case .success(let tuple) = result {
                        let (_, tag) = tuple
                        return tag == thisSendCount
                    } else if case .failure(let error) = result, case SendError.sendFailed(let tag) = error {
                        return tag == thisSendCount
                    } else {
                        return false
                    }
                })
                .sink(receiveValue: { result in
                    if case .success(let tuple) = result {
                        continuation.resume(returning: tuple)
                    } else if case .failure(let error) = result {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ConnectError.noAddressReturned)
                    }
                })

            socket.write(encryedData ?? data, withTimeout: timeout, tag: thisSendCount)
            if let readLength = readLength {
                socket.readData(toLength: readLength, withTimeout: timeout, tag: thisSendCount)
            } else if !skipRead {
                socket.readData(withTimeout: timeout, tag: thisSendCount)
            }
        }
        return recv
    }

    public func read(toLength: UInt) async throws -> (Data, Int) {
        sendCount += 1
        let thisSendCount = sendCount
        let recv = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, Int), Error>) in
            delegate?.didSend = nil
            sendCancellable = delegate?.$didSend
                .first(where: { result in
                    if case .success(let tuple) = result {
                        let (_, tag) = tuple
                        return tag == thisSendCount
                    } else if case .failure(let error) = result, case SendError.sendFailed(let tag) = error {
                        return tag == thisSendCount
                    } else {
                        return false
                    }
                })
                .sink(receiveValue: { result in
                    if case .success(let tuple) = result {
                        continuation.resume(returning: tuple)
                    } else if case .failure(let error) = result {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ConnectError.noAddressReturned)
                    }
                })
            socket.readData(toLength: toLength, withTimeout: timeout, tag: thisSendCount)
        }

        return recv
    }

    nonisolated public func disconnect() {
        socket.disconnectAfterReadingAndWriting()
    }
}
