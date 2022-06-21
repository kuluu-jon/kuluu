//
//  HeadlessSessionViewModel.swift
//  ffxi
//
//  Created by kuluu-jon on 5/25/22.
//

import SwiftUI
import kuluu_ffxi_network_protocol

@MainActor class HeadlessSessionViewModel: ObservableObject, Identifiable, Equatable {
    nonisolated static func == (lhs: HeadlessSessionViewModel, rhs: HeadlessSessionViewModel) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated let id: String = UUID().uuidString

    let client: FFXIClient

    @Published private(set) var selectedIndex: Int?
    @Published private(set) var sessions: [HeadlessSessionViewModel] {
        didSet {
            guard sessions != oldValue else { return }
            maps = sessions.compactMap { $0.client.map }
        }
    }
    @Published private(set) var maps: [SelectCharacterResponse]

    @Published var error: Error?
    @Published var isSaved: Bool = false {
        didSet {
            guard isSaved != oldValue else { return }
            UserDefaults.standard.set(isSaved, forKey: "isSaved")
            if !isSaved {
                UserDefaults.standard.set(nil, forKey: "username")
                UserDefaults.standard.set(nil, forKey: "password")
            }
        }
    }
    @Published var host: String = "127.0.0.1"
    @Published var port: String = "54231"
    @Published var username: String = ""
    @Published var password: String = ""

    init(client: FFXIClient) {
        self.client = client
        sessions = []
        maps = []
        selectedIndex = 0
    }

    func onAppear() {
        DispatchQueue.main.async {
            if let username = UserDefaults.standard.string(forKey: "username") {
                self.username = username
            }
            if let password = UserDefaults.standard.string(forKey: "password") {
                self.password = password
            }
            self.isSaved = UserDefaults.standard.bool(forKey: "isSaved")
        }
    }

    func onDisappear() {
//        client.disconnect()
    }

    func newSession() {
        sessions.append(.init(client: .init()))
        selectedIndex = sessions.indices.last
    }

    func close(session: HeadlessSessionViewModel) {
        if let sessionIndex = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions.remove(at: sessionIndex)
            selectedIndex = sessions.indices.first
        }
    }

    func login() {
        Task {
            do {
                try await client.login(host: host, port: port, username: username, password: password)

                await MainActor.run {
                    if self.isSaved {
                        UserDefaults.standard.set(username, forKey: "username")
                        UserDefaults.standard.set(password, forKey: "password")
                        UserDefaults.standard.synchronize()
                    }
                    self.objectWillChange.send()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
}
