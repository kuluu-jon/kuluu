//
//  HeadlessFFXIApp.swift
//  Shared
//
//  Created by kuluu-jon on 5/7/22.
//

import SwiftUI
import kuluu_ffxi_network_protocol

enum OpenWindows: String, CaseIterable {
    case game = "game"
    // As many views as you need.

    func open() {
        if let url = URL(string: "kuluu://\(self.rawValue)") { // replace myapp with your app's name
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url, options: [:])
            #endif
        }
    }
}

@main
struct HeadlessFFXIApp: App {
    @StateObject private var viewModel: HeadlessFFXIAppViewModel = .init()

    init() {

    }

    @ViewBuilder var body: some Scene {
        #if OFFLINE
        WindowGroup("Project Kuluu", id: OpenWindows.game.rawValue) {
            ForEach(viewModel.sessions) { session in
                if let selectedCharacter = session.client.selectedCharacter, let map = session.client.map {
                    HeadlessMap(
                        gameView: GameView.init(client:),
                        map: map,
                        character: selectedCharacter
                    )
                        .frame(minWidth: 1280, minHeight: 720, alignment: .center)
                        .environmentObject(session.client)
                        .onAppear {
                            print("why")
                        }
                        .onDisappear {
                            session.client.disconnect()
                        }
                }
            }
            if viewModel.sessions.isEmpty {
                Text("hi")
                    .frame(width: 1, height: 1, alignment: .center)
                    .opacity(0.01).onAppear {
                    let session = HeadlessSessionViewModel(client: .init())
                    let map = SelectCharacterResponse(zoneIp: "127.0.0.1", zonePort: 53230, searchIp: "0.0.0.0", searchPort: 80)
                    session.client.selectedCharacter = .dummy
                    viewModel.maps = [map]
                    session.client.map = map
                    viewModel.sessions = [session]
                }
            }
        }
        #else
        WindowGroup("Project Kuluu Launcher", id: "launcher") {
            #if os(iOS)
            if viewModel.sessions.first?.client.selectedCharacter != nil {
                ForEach(viewModel.sessions) { session in
                    if let selectedCharacter = session.client.selectedCharacter, let map = session.client.map {
                        HeadlessMap(
                            gameView: GameView.init(client:),
                            map: map,
                            character: selectedCharacter
                        )
                            .environmentObject(session.client)
                            .onAppear {
                                print("why")
                            }
                            .onDisappear {
                                session.client.disconnect()
                            }
                    }
                }
            } else {
                AccountSelectionList().environmentObject(viewModel)
            }

            #else
            AccountSelectionList().environmentObject(viewModel)
            #endif

        }

        #if os(macOS)
        Settings {
            List {
                Toggle("Example", isOn: .constant(true))
                TextField("Thing", text: .constant("ping"))
                Button("OK") { }
            }
            .frame(idealWidth: 400, idealHeight: 500)
            .environmentObject(viewModel)
        }
        WindowGroup("Project Kuluu", id: OpenWindows.game.rawValue) {
            ForEach(viewModel.sessions) { session in
                if let selectedCharacter = session.client.selectedCharacter, let map = session.client.map {
                    HeadlessMap(
                        gameView: GameView.init(client:),
                        map: map,
                        character: selectedCharacter
                    )
                        .environmentObject(session.client)
                        .onAppear {
                            print("why")
                        }
                        .onDisappear {
                            session.client.disconnect()
                        }
                }
            }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: OpenWindows.game.rawValue))
        #endif
        #endif
    }
}
