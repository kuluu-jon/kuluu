//
//  Headless.swift
//  ffxi iOS
//
//  Created by kuluu-jon on 5/7/22.
//

import SwiftUI
import Networking

struct HeadlessSession: View {
    @FocusState private var focusedField: Field?
    @ObservedObject var viewModel: HeadlessSessionViewModel

    enum Field: Hashable {
       case host, port, username, password
    }
    
    init(viewModel: HeadlessSessionViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { g in
            NavigationView {
                self.bodyContent.frame(width: g.size.width)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

private extension HeadlessSession {
    @ViewBuilder var bodyContent: some View {
        if let lobby = viewModel.client.lobby {
            self.lobby(lobby)
        } else {
            serverAndAccountConfig.navigationTitle("New Session")
        }
    }
    
    func lobby(_ lobby: LobbyState) -> some View {
        CharacterPicker(lobby: lobby)
            .environmentObject(viewModel.client)
    }
    
    var serverAndAccountConfig: some View {
        VStack {
            TextField(
                "Server Hostname / IP",
                text: $viewModel.host
            )
                .focused($focusedField, equals: .host)
            TextField(
                "Server Port",
                text: $viewModel.port
            )
                .focused($focusedField, equals: .port)
            TextField(
                "Account Name",
                text: $viewModel.username
            )
                .focused($focusedField, equals: .username)
            TextField(
                "Password",
                text: $viewModel.password
            )
                .focused($focusedField, equals: .password)
//                .textFieldStyle(.squareBorder)
            
            Toggle("Save account and password", isOn: $viewModel.isSaved)
            Button.init(action: {
                viewModel.login()
            }, label: { Label("Login", systemImage: "arrow.right")})
        }
        .onAppear {
            DispatchQueue.main.async {
                if !self.viewModel.isSaved {
                    self.focusedField = .username
                }
            }
        }
        .frame(width: 400, height: 400, alignment: .center)
    }
}


struct HeadlessSession_Previews: PreviewProvider {
    static var previews: some View {
        HeadlessSession(viewModel: .init(client: .init()))
    }
}
