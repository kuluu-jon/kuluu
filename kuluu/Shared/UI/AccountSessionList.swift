//
//  AccountSessionList.swift
//  ffxi
//
//  Created by kuluu-jon on 5/25/22.
//

import Foundation

import SwiftUI
import Networking

struct AccountSelectionList: View {
    
    @EnvironmentObject var appViewModel: HeadlessFFXIAppViewModel
    
    var body: some View {
        NavigationView {
    //                var index = 0
            List(appViewModel.sessions.indices, id: \.self, selection: $appViewModel.selectedIndex) { index in

                let session = appViewModel.sessions[index]
                let map = session.client.map
    //                    let client = clients[index]
                let isSelected = appViewModel.selectedIndex == index
    //                    index += 1
//                session
                VStack {
                NavigationLink(destination: {
                    HeadlessSession(viewModel: session)
                }, label: {
                    HStack {
                        if let map = map {
//                        ForEach(appViewModel.maps, id: \.self) { map in
                            VStack {
                                Text(map.zoneIp)
                                Text(session.host)
                            }
                            .id("mapRow")
                        } else {
                            Text("New Session").id("mapRow")
                        }
                        Spacer(minLength: 20)
                        Button(action: {
                            appViewModel.close(session: session)
                        }) {
                            Image(systemName: "xmark.circle")
                        }
                        .buttonStyle(.plain)
                    }

                })
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 1)
                        .fill()
                        .foregroundColor(Color.orange.opacity(isSelected ? 1 : 0.5))
                )
                .id(index)
            }.toolbar {
                Button(action: {
                    appViewModel.newSession()
                }) {
                    Text("New Session")
                    Label("New Session", systemImage: "person.crop.circle.badge.plus")
                }
            }
            .navigationTitle("Sessions")
            
        }
        .onAppear { DispatchQueue.main.async { appViewModel.newSession() } }
    }
//    WindowGroup.init("Sessions", id: "sessions") {
//        #if os(iOS)
//        GameView(selectedCharacter: .init(zoneIp: "127.0.0.1", zonePort: 54230, searchIp: "127.0.0.1", searchPort: 54231)).landscape()
//        #else
//
//    }
}

