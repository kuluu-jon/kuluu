//
//  HeadlessFFXIApp.swift
//  Shared
//
//  Created by kuluu-jon on 5/7/22.
//

import SwiftUI

enum OpenWindows: String, CaseIterable {
    case game = "game"
    //As many views as you need.
    
    func open() {
        if let url = URL(string: "kuluu://\(self.rawValue)") { //replace myapp with your app's name
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
                .id("heyo")
            } else {
                AccountSelectionList().environmentObject(viewModel).id("heyo")
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
    }
}
