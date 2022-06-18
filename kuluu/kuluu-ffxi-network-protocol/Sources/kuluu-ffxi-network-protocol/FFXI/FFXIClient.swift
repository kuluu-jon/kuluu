//
//  FFXIClient.swift
//  
//
//  Created by kuluu-jon on 1/3/22.
//

import CocoaAsyncSocket
import BinaryCodable
import Combine

@MainActor public class FFXIClient: ObservableObject, Identifiable {
    public let id: String = UUID().uuidString
    private let lobbyClient: FFXILobby
    private var mapClient: FFXIMap?
    private let clientVersion: String

    @Published public var selectedCharacter: AccountResponse.CharacterSlot?
    @Published public var map: SelectCharacterResponse? {
        didSet {
            if let map = map, let selectedCharacter = selectedCharacter {
                mapClient = FFXIMap(
                    character: selectedCharacter,
                    mapNet: .init(host: map.zoneIp, port: map.zonePort, clientVersion: clientVersion),
                    searchNet: .init(host: map.searchIp, port: map.searchPort, clientVersion: clientVersion)
                )
            }
        }
    }
    @Published private(set) public var lobby: LobbyState?

    public init(clientVersion: String = "30181250_0") {
        self.clientVersion = clientVersion
        self.lobbyClient = .init(clientVersion: clientVersion)
    }

    public func disconnect() {
        Task {
            await lobbyClient.disconnect()
            await MainActor.run {
                map = nil
                mapClient = nil
                lobby = nil
                selectedCharacter = nil
            }
        }
    }
}

extension FFXIClient: ProvidesLobby {
    public func selectCharacter(_ character: AccountResponse.CharacterSlot) async throws {
        try await lobbyClient.selectCharacter(character)
        let map = await lobbyClient.map
        await MainActor.run {
            self.selectedCharacter = character
            self.map = map
        }
    }

    public func login(host: String, port: String, username: String, password: String) async throws {
        try await lobbyClient.login(host: host, port: port, username: username, password: password)
        let lobby = await lobbyClient.lobby
        await MainActor.run {
            self.lobby = lobby
        }
    }
}

extension FFXIClient: ProvidesMap {

    public func connect() async throws {
        try await mapClient?.connect()
    }

    public func zoneIn() async throws {
        try await mapClient?.zoneIn()
    }

    public func logout() async throws {
        // await logout()
        try await mapClient?.logout()

        disconnect()
    }

    public func send(chatMessage: String) async throws {
        try await mapClient?.send(chatMessage: chatMessage)
    }

    public func sync(position: SIMD3<Float>, rotation: Float) async throws {
        try await mapClient?.sync(position: position, rotation: rotation)
    }
}
