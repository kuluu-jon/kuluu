//
//  CharacterPicker.swift
//  ffxi
//
//  Created by kuluu-jon on 5/7/22.
//

import SwiftUI
import Networking

struct CharacterPicker: View {
    @EnvironmentObject var kuluuClient: FFXIClient
    let lobby: LobbyState
    let nf = NumberFormatter()
    var isEnabled: Bool {
        kuluuClient.map == nil
    }
    
    var body: some View {
        
        if lobby.account.characterSlots.isEmpty {
            Text(
                """
                accountId: \(lobby.accountId.description),
                server {
                  expansion: \(lobby.serverConfig.expansionBitmask.description),
                  features: \(lobby.serverConfig.featureBitmask.description)
                }
                """
            )
            Text("but no characters?")
        } else {
            List(lobby.account.characterSlots) { character in
                
                Text(
                """
                accountId: \(lobby.accountId.description),
                server {
                  expansion: \(lobby.serverConfig.expansionBitmask.description),
                  features: \(lobby.serverConfig.featureBitmask.description)
                }
                """
                )
                    .font(.body.monospaced())
    //                .background(Color.background)
                
                Divider()
                
                Button(action: { self.selectCharacter(character)}) {
                    HStack {
                        Spacer()
                        Text(isEnabled ? "Login" : "Playing")
                        Divider()
    //                    Image(systemName: "person.crop.circle") // figure out race / appearance and render
                        VStack(alignment: .leading) {
                            Text(character.name ?? "N/A")
                            Text("{id: \(nf.string(from: NSNumber(integerLiteral: Int(character.id))) ?? "N/A")}")
                                .font(.body.monospaced())
                        }
                        .padding()
                        .background(Color.accentColor.opacity(0.2))
                        
                        Spacer()
                    }
                }
                .id(character.id)
                .background(RoundedRectangle(cornerRadius: 1).fill().foregroundColor(Color.accentColor))
                .buttonStyle(.plain)
                .frame(minHeight: 50)
                .disabled(!isEnabled)
            }
            .navigationTitle("Select Character")
//            .navigationLink(item: $kuluuClient.map, destination: {
//                if let selectedCharacter = kuluuClient.selectedCharacter {
//                    HeadlessMap(
//                        gameView: GameView.init(client:),
//                        map: $0,
//                        character: selectedCharacter
//                    ).environmentObject(kuluuClient)
//                }
//            })
        }
    }
}

private extension CharacterPicker {
    func selectCharacter(_ character: AccountResponse.CharacterSlot) {
        Task {
            //: slot might be off by one?
            try await self.kuluuClient.selectCharacter(character)
            await MainActor.run {
                self.kuluuClient.objectWillChange.send()
                OpenWindows.game.open()
//                selectedCharacter = character
            }
        }
    }
}

//struct CharacterPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        CharacterPicker(lobby: FFXILobby.Lobby())
//    }
//}
