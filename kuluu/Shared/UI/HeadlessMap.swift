//
//  HeadlessMap.swift
//  ffxi
//
//  Created by kuluu-jon on 5/7/22.
//

import SwiftUI
import Networking

struct HeadlessMap<GameView: View>: View {
    let gameView: (FFXIClient) -> GameView
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var kuluuClient: FFXIClient
    @State var chatMessage: String = ""
    let map: SelectCharacterResponse
    let character: AccountResponse.CharacterSlot
    let nf = NumberFormatter()

    var body: some View {
        VStack {
            self.gameView(kuluuClient)
//                .overlay(self.partyList, alignment: .bottomTrailing)
            Text(map.zoneIp)
            Text(map.searchIp)
            Text(map.searchPort.description)
            HStack {
                TextField.init(text: $chatMessage, prompt: Text("Send Message"), label: { Text("Send Message") }).onSubmit {
                    let chatMessage = self.chatMessage
                    Task {
                        try? await kuluuClient.send(chatMessage: chatMessage)
                    }
                }
                Button.init(action: {
                    
                    let chatMessage = self.chatMessage
                    Task {
                        try? await kuluuClient.send(chatMessage: chatMessage)
                    }
                }, label: {
                    Text("Send")
                })
            }
        }
        .navigationTitle("\(character.name ?? "???") @ \(map.zoneIp):\(nf.string(from: NSNumber(integerLiteral: Int(map.zonePort))) ?? "N/A")")
        .toolbar {
            Button(action: { self.presentationMode.wrappedValue.dismiss() }, label: { Text("Exit") })
        }
        .task {
            do {
                try await kuluuClient.connect()
                try await kuluuClient.zoneIn()
                print("logged in")
            } catch {
                print("error", error)
            }
        }
    }
}

private extension HeadlessMap {
    var partyList: some View {
        VStack {
            if let name = character.name {
                ProgressView(value: 1, label: { Text("HP") })
                    .progressViewStyle(.linear)
                ProgressView(value: 0.5, label: { Text("MP") })
                    .progressViewStyle(.linear)
                Text(name)
            }
        }
        .background(Color.secondary)
    }
}

//struct HeadlessMap_Previews: PreviewProvider {
//    static var previews: some View {
//        HeadlessMap(map: .init(from: ))
//    }
//}
