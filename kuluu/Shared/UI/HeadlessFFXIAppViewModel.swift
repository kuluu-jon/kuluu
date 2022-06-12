//
//  HeadlessFFXIAppViewModel.swift
//  ffxi
//
//  Created by kuluu-jon on 5/25/22.
//

import SwiftUI
import kuluu_ffxi_network_protocol

@MainActor class HeadlessFFXIAppViewModel: ObservableObject {

    @Published var selectedIndex: Int?
    #if OFFLINE
    @Published var sessions: [HeadlessSessionViewModel] {
        didSet {
            guard sessions != oldValue else { return }
            maps = sessions.compactMap { $0.client.map }

        }
    }
    @Published var maps: [SelectCharacterResponse]
    #else
    @Published private(set) var sessions: [HeadlessSessionViewModel] {
        didSet {
            guard sessions != oldValue else { return }
            maps = sessions.compactMap { $0.client.map }

        }
    }
    @Published private(set) var maps: [SelectCharacterResponse]
    #endif

    init() {
        sessions = []
        maps = []
        selectedIndex = 0
    }

    func newSession() {
        sessions.append(.init(client: .init()))
//        sessions = clients.map(HeadlessSession.init(kuluuClient:))
        selectedIndex = sessions.indices.last
    }

    func close(session: HeadlessSessionViewModel) {
        if let sessionIndex = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions.remove(at: sessionIndex)
            selectedIndex = sessions.indices.first
        }
    }
}
