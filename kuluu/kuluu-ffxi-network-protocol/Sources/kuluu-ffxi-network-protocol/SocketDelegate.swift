//
//  File.swift
//  
//
//  Created by kuluu-jon on 1/3/22.
//

import CocoaAsyncSocket
import SwiftUI

class UdpSocketDelegate: NSObject, ObservableObject, GCDAsyncUdpSocketDelegate {
    let logId = "udp[" + String(UUID().uuidString.prefix(3)) + "]"

    @Published var didConnect: Result<Data, Error>?
    @Published var didSend: Result<Int, Error>?
    @Published var didReceive: Result<Data, Error>?
    @Published var error: Error?

    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        let ip = address.map(String.init).joined(separator: ".")
        print(logId, "didConnectToAddress", ip)
        didConnect = .success(address)
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        if let error = error {
            didConnect = .failure(error)
            print(logId, "didNotConnect error:", error)
        } else {
            didConnect = .failure(UDPNetworking.ConnectError.noAddressReturned)
            print(logId, "didNotConnect without error")
        }
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        print(logId, "didReceive data", data)
        didReceive = .success(data)
    }

    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        if let error = error {
            let ns = (error as NSError)
            let code = GCDAsyncSocketError.Code(rawValue: ns.code)
            print(logId, "udpSocketDidClose with error", ns.localizedDescription, "| code", code?.rawValue ?? "")
        } else {
            print(logId, "udpSocketDidClose without error")
        }
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print(logId, "didSendDataWithTag:", tag)
        didSend = .success(tag)
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        if let error = error {
            print(logId, "didNotSendDataWithTag:", tag, "error:", error)
        } else {
            print(logId, "didNotSendDataWithTag:", tag, "without error")
        }
        didSend = .failure(UDPNetworking.SendError.sendFailed(tag: tag))
    }
}

class TcpSocketDelegate: NSObject, ObservableObject, GCDAsyncSocketDelegate {
    let logId = "tcp-[" + String(UUID().uuidString.prefix(3)) + "]"

    @Published var didConnect: Result<URL, Error>?
    @Published var didSend: Result<(Data, Int), Error>?
    @Published var didRead: Result<(Data, Int), Error>?
    @Published var error: Error?

    func socket(_ sock: GCDAsyncSocket, didConnectTo url: URL) {
        print(logId, "didConnectTo", url)
        didConnect = .success(url)
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if let err = err {
            let ns = (err as NSError)
            let code = GCDAsyncSocketError.Code(rawValue: ns.code)
            print(
                logId,
                "socketDidDisconnect",
                err.localizedDescription, "| code", code?.rawValue ?? ""
            )

            didConnect = .failure(err)
            didSend = .failure(err)
        } else {
            print(logId, "socketDidDisconnect")
        }
    }

    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        var uc = URLComponents()
        uc.host = host
        uc.port = Int(port)
        didConnect = .success(uc.url!)
    }

    func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        print(logId, "socketDidCloseReadStream")
        didSend = nil
        didConnect = nil
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print(logId, "socketDidRead", data.toHexString(), "withTag", tag)
        didSend = .success((data, tag))
        didRead = .success((data, tag))
    }

    func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        print(logId, "socketDidReadPartialDataOfLength", partialLength, "withTag", tag)
        didSend = .success((Data(), tag))
    }
}
