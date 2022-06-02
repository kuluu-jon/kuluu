//
//  FFXILoginClient.swift
//
//  Reference: https://github.com/zach2good/HeadlessXI
//
//  Created by kuluu-jon on 5/6/22.
//
import BinaryCodable
import Darwin
import Foundation
import CryptoSwift

public protocol ProvidesLobby {
    func login(host: String, port: String, username: String, password: String) async throws
    func selectCharacter(_ character: AccountResponse.CharacterSlot) async throws
}

public struct ServerConfigResponse: BinaryDecodable {
    public let expansionBitmask: UInt32
    public let featureBitmask: UInt32
    public init(from decoder: BinaryDecoder) throws {
        var c = decoder.container(maxLength: 40)
        _ = try c.decode(length: 32) // don't care
        self.expansionBitmask = try c.decode(UInt32.self)
        self.featureBitmask = try c.decode(UInt32.self)
    }
}

public struct AccountResponse: BinaryDecodable {
    public struct CharacterSlot: BinaryDecodable, Identifiable {
        public let id: UInt32
        public let name: String?
        public init(from decoder: BinaryDecoder) throws {
            var c = decoder.container(maxLength: 140)
            self.id = try c.decode(UInt32.self)
            _ = try c.decode(UInt32.self)
            let nameData = try c.decode(length: 16)
            self.name = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .letters.inverted)
            //                _ = try c.decode(length: 1) // don't care
        }
    }
    public let characterSlots: [CharacterSlot]
    public init(from decoder: BinaryDecoder) throws {
        var c = decoder.container(maxLength: 2272)
        let header = try c.decode(length: 36)
        print(header.toHexString())
        var slots: [CharacterSlot] = []
        while try c.peek(length: 1).bytes.first != 0 {
            let slot = try c.decode(CharacterSlot.self)
            if slot.name?.isEmpty == false {
                slots.append(slot)
            }
        }
        self.characterSlots = slots
    }
}

public struct LobbyState {
    public let accountId: UInt16
    public let serverConfig: ServerConfigResponse
    public let account: AccountResponse
}

public struct SelectCharacterResponse: BinaryDecodable, Hashable {
    
//    public let statusCode: UInt16
    public let zoneIp: String
    public let zonePort: UInt16
    public let searchIp: String
    public let searchPort: UInt16
    
    public init(from decoder: BinaryDecoder) throws {
        var c = decoder.container(maxLength: 72)
        let data = try c.decode(length: 56)
        print(data.toHexString())
        let zoneIpData = try c.decode(length: 4)
        zoneIp = zoneIpData.map(String.init).joined(separator: ".")
        zonePort = try c.decode(UInt16.self)
        let searchIpData = try c.decode(length: 4)
        searchIp = searchIpData.map(String.init).joined(separator: ".")
        searchPort = try c.decode(UInt16.self)
    }
    
    public init(zoneIp: String, zonePort: UInt16, searchIp: String, searchPort: UInt16) {
        self.zoneIp = zoneIp
        self.zonePort = zonePort
        self.searchIp = searchIp
        self.searchPort = searchPort
    }
}


enum FFXILobbyError: Error {
    case invalidData(String)
    case unauthenticated
}

public actor FFXILobby: ProvidesLobby {
    
    private var net: TCPNetworking!
    private var lobbyDataNet: TCPNetworking!
    private var lobbyViewNet: TCPNetworking!
    private let decoder = BinaryDataDecoder()
    private let encoder = BinaryDataEncoder()
    private let clientVersion: String
    
    private(set) public var lobby: LobbyState? {
        didSet {
            if lobby == nil {
                self.map = nil
            }
        }
    }
    private(set) public var map: SelectCharacterResponse?
    
    init(clientVersion: String) {
        self.clientVersion = clientVersion
    }
    
    deinit {
        disconnect()
    }
    
    public func disconnect() {
        net?.disconnect()
        lobbyViewNet?.disconnect()
        lobbyDataNet?.disconnect()
        map = nil
    }
    
    public func login(host: String, port: String, username: String, password: String) async throws {
        // get account id
        self.net = .init(host: host, port: UInt16(port)!, clientVersion: clientVersion)
        self.lobbyDataNet = .init(host: host, port: UInt16(port)! - 1, clientVersion: clientVersion)
        self.lobbyViewNet = .init(host: host, port: UInt16(port)! - 230, clientVersion: clientVersion)
        let loginResponse = try await authenticate(username: username, password: password)
        
        // start connect w/ lobby data
        try await sendLobbyData0xA1_0(accountId: loginResponse.accountId)
        // start connect w/ lobby view
        let serverConfig = try await sendLobbyView0x26()
        try await sendLobbyView0x1F()
        let account = try await sendLobbyData0xA1_1()
        print("first character:", account.characterSlots.first?.name ?? "nil", "server feature flags:", serverConfig.featureBitmask, "expansion", serverConfig.expansionBitmask)
        
        self.lobby = .init(accountId: loginResponse.accountId, serverConfig: serverConfig, account: account)
    }
    
    public func selectCharacter(_ character: AccountResponse.CharacterSlot) async throws {
        guard self.lobby != nil else {
            throw FFXILobbyError.unauthenticated
        }
        try await sendLobbyView0x07(charId: character.id)
        let map = try await sendLobbyData0xA2()
        self.map = map
    }
}

// authentication, first handshake where we get account id for un/pw
private extension FFXILobby {
    
    struct LoginPacket: BinaryEncodable {
        let username: String
        let password: String
        let code: UInt8 = 0x10 // LOGIN_ATTEMPT
        func encode(to encoder: BinaryEncoder) throws {
            var container = encoder.container()
            let u = username.padding(toLength: 16, withPad: "\0", startingAt: 0)
            let p = password.padding(toLength: 16, withPad: "\0", startingAt: 0)
            try container.encode(u, encoding: .ascii, terminator: nil)
            try container.encode(p, encoding: .ascii, terminator: nil)
            try container.encode(code)
        }
    }
    
    struct LoginResponse: BinaryDecodable {
        let responseCode: UInt8 // 1 = success, 2 = invalid un/pw, other = failed
        let accountId: UInt16
        
        init(from decoder: BinaryDecoder) throws {
            var container = decoder.container(maxLength: 16)
            self.responseCode = try container.decode(UInt8.self)
            self.accountId = try container.decode(UInt16.self)
        }
    }
    
    func authenticate(username: String, password: String) async throws -> LoginResponse  {
        try await self.net.connect()
        defer { self.net.disconnect() }
        
        let packet = LoginPacket(username: username, password: password)
        let packetData = try encoder.encode(packet)
        guard let (data, _) = try await self.net.write(data: packetData, readLength: 16)
        else { throw FFXILobbyError.invalidData("no response from login") }
        
        guard let response = try? decoder.decode(LoginResponse.self, from: data) else {
            throw FFXILobbyError.invalidData("could not decode login response")
        }
        return response
    }
}

private extension FFXILobby {
    /*
     def lobby_data_0xA1_0(self):
     print('Sending lobby_data_0xA1 (0)')
     try:
     data = bytearray(5)
     data[0] = 0xA1
     util.memcpy(util.pack_32(self.account_id), 0, data, 1, 4)
     self.lobbydata_sock.sendall(data)
     except Exception as ex:
     print(ex)
     */
    func sendLobbyData0xA1_0(accountId: UInt16) async throws {
        struct LobbyData0xA1: BinaryEncodable {
            let id: UInt8 = 0xA1
            let accountId: UInt32
            
            func encode(to encoder: BinaryEncoder) throws {
                var container = encoder.container()
                try container.encode(id)
                try container.encode(accountId)
            }
        }
        
        try await self.lobbyDataNet.connect()
        let packet = LobbyData0xA1(accountId: .init(accountId))
        let packetData = try encoder.encode(packet)
        try await self.lobbyDataNet.write(data: packetData)
    }
}

private extension FFXILobby {
    struct LobbyView0x26: BinaryEncodable {
        let id: UInt8 = 0x26
        let clientVersion: String
        
        func encode(to encoder: BinaryEncoder) throws {
            var container = encoder.container()
            let zero = UInt8(0)
            let pad1: [UInt8] = .init(repeating: zero, count: 8)
            try container.encode(sequence: pad1)
            try container.encode(id)
            let pad2: [UInt8] = .init(repeating: zero, count: 107)
            try container.encode(sequence: pad2)
            let cv = clientVersion.padding(toLength: 10, withPad: "\0", startingAt: 0)
            try container.encode(cv, encoding: .ascii, terminator: nil)
            let pad3: [UInt8] = .init(repeating: zero, count: 26)
            try container.encode(sequence: pad3)
        }
    }
    /*
     def lobby_view_0x26(self):
     print('Sending lobby_view_0x26')
     try:
     data = bytearray(152)
     data[8] = 0x26
     util.memcpy(self.client_str, 0, data, 116, 10)
     self.lobbyview_sock.sendall(data)
     
     in_data = self.lobbyview_sock.recv(40)
     
     expansion_bitmask = util.unpack_uint32(in_data, 32)
     print('Expansion bitmask: ' + str(bin(expansion_bitmask)) + ' (' +
     str(expansion_bitmask) + ')')
     
     feature_bitmask = util.unpack_uint16(in_data, 36)
     print('Feature bitmask: ' + str(bin(feature_bitmask)) + ' (' +
     str(feature_bitmask) + ')')
     except Exception as ex:
     print(ex)
     */
    func sendLobbyView0x26() async throws -> ServerConfigResponse {
        try await self.lobbyViewNet.connect()
        let packet = LobbyView0x26(clientVersion: clientVersion)
        
        let packetData = try encoder.encode(packet)
        guard let (data, _) = try await self.lobbyViewNet.write(data: packetData, readLength: 40)
        else { throw FFXILobbyError.invalidData("no response from 0x26") }
        
        guard let response = try? decoder.decode(ServerConfigResponse.self, from: data) else {
            throw FFXILobbyError.invalidData("could not decode login response")
        }
        return response
    }
}

private extension FFXILobby {
    /*
     def lobby_view_0x1F(self):
     print('Sending lobby_view_0x1F')
     try:
     data = bytearray(44)
     data[8] = 0x1F
     self.lobbyview_sock.sendall(data)
     except Exception as ex:
     print(ex)
     */
    func sendLobbyView0x1F() async throws {
        struct LobbyView0x1F: BinaryEncodable {
            let id: UInt8 = 0x1F
            
            func encode(to encoder: BinaryEncoder) throws {
                var container = encoder.container()
                let zero = UInt8(0)
                let pad1: [UInt8] = .init(repeating: zero, count: 8)
                try container.encode(sequence: pad1)
                try container.encode(id)
                let pad2: [UInt8] = .init(repeating: zero, count: 35)
                try container.encode(sequence: pad2)
            }
        }
        
        let packet = LobbyView0x1F()
        let packetData = try encoder.encode(packet)
        try await self.lobbyDataNet.write(data: packetData)
    }
}

private extension FFXILobby {
    /*
     def lobby_data_0xA1_1(self):
     print('Sending lobby_data_0xA1 (1)')
     try:
     # Should send 9 bytes: A1 00 00 01 00 00 00 00 00
     data = bytearray.fromhex('A10000010000000000')
     
     # Sends: bytearray(b'\xa1\x00\x00\x01\x00\x00\x00\x00\x00')
     self.lobbydata_sock.sendall(data)
     
     _ = self.lobbydata_sock.recv(328)
     data = self.lobbyview_sock.recv(2272)
     
     if data[36] != 0 and data[36 + self.slot * 140] != 0:
     self.char_id = util.unpack_uint32(data, 36 + (self.slot * 140))
     
     self.char_name = data[44 + (self.slot * 140):44 +
     (self.slot * 140) + 16].decode(
     'utf-8', 'ignore')
     self.char_name = re.sub(r'\d+', '', self.char_name)
    
     print(self.char_id, self.char_name)
     except Exception as ex:
     print(ex)
     */
    
    func sendLobbyData0xA1_1() async throws -> AccountResponse {
        let packetData = Data([0xA1, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00])
        guard let (_, _) = try await self.lobbyDataNet.write(data: packetData, readLength: 328) else {
            throw FFXILobbyError.invalidData("sendLobbyData0xA1_1")
        }
        let (data, _) = try await self.lobbyViewNet.read(toLength: 2272)
        let response = try decoder.decode(AccountResponse.self, from: data)
        return response
    }
}

private extension FFXILobby {
    /*
     def lobby_view_0x07(self):
     print('Sending lobby_view_0x07')
     try:
     data = bytearray(88)
     data[8] = 0x07
     util.memcpy(util.pack_32(self.char_id), 0, data, 28, 4)
     self.lobbyview_sock.sendall(data)
     except Exception as ex:
     print(ex)
     */
    func sendLobbyView0x07(charId: UInt32) async throws {
        struct LobbyView0x07: BinaryEncodable {
            let id: UInt8 = 0x07
            let charId: UInt32
            
            func encode(to encoder: BinaryEncoder) throws {
                var container = encoder.container()
                let zero = UInt8(0)
                let pad1: [UInt8] = .init(repeating: zero, count: 8)
                try container.encode(sequence: pad1)
                try container.encode(id)
                let pad2: [UInt8] = .init(repeating: zero, count: 19)
                try container.encode(sequence: pad2)
                try container.encode(charId)
            }
        }
        
        let packet = LobbyView0x07(charId: charId)
        let packetData = try encoder.encode(packet)
        try await self.lobbyViewNet.write(data: packetData)
    }
}

private extension FFXILobby {
    /*
     def lobby_data_0xA2(self):
     print('Sending lobby_data_0xA2')
     time.sleep(2)
     data = bytearray([
     0xA2, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
     0x00, 0x00, 0x00
     ])
     
     status_code = 0
     try:
     self.lobbydata_sock.sendall(data)
     data = self.lobbyview_sock.recv(72) #0x48
     if len(data) != 0x48:
     raise Exception(f"Did not get back 72 bytes. Got {len(data)}. => {data}")
     #status_code = util.unpack_uint16(data, 32)
     #if status_code != 305 and status_code != 321:
     #    raise Exception("Did not get acceptable status code")
     except Exception as ex:
     print(f'Error communicating lobby 0xA2 packet. Error: {status_code}')
     print(ex)
     exit(-1)
     
     try:
     self.zone_ip = util.int_to_ip(
     socket.htonl(util.unpack_uint32(data, 0x38)))
     self.zone_port = util.unpack_uint16(data, 0x3C)
     self.search_ip = util.int_to_ip(
     socket.htonl(util.unpack_uint32(data, 0x40)))
     self.search_port = util.unpack_uint16(data, 0x44)
     except Exception as ex:
     print(f'Error unpacking gameserver handoff data.')
     print(ex)
     exit(-1)
     
     self.map_server = (self.zone_ip, self.zone_port)
     self.search_server = (self.search_ip, self.search_port)
     
     print(f'ZoneServ: {self.map_server}, SearchServ: {self.search_server}')
     */
    
    func sendLobbyData0xA2() async throws -> SelectCharacterResponse {
        assert(!Thread.isMainThread)
        let packet: [UInt8] = [
            0xA2, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x58,
            0xE0, 0x5D, 0xAD, 0x00, 0x00, 0x00, 0x00
        ]
        let packetData = Data(packet)
        try await lobbyDataNet.write(data: packetData)
        let (data, _) = try await lobbyViewNet.read(toLength: 72)
        let response = try decoder.decode(SelectCharacterResponse.self, from: data)
        return response
    }
}
