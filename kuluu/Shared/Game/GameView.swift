//
//  GameView.swift
//  ffxi
//
//  Created by kuluu-jon on 5/14/22.
//

import SwiftUI
import kuluu_ffxi_network_protocol

#if os(macOS)
import AppKit
typealias VCRep = NSViewControllerRepresentable
typealias VC = NSViewController
#else
import UIKit
typealias VCRep = UIViewControllerRepresentable
typealias VC = UIViewController
#endif

struct GameView: VCRep {

    let client: FFXIClient
    typealias NSViewControllerType = VC

    #if os(macOS)
    func updateNSViewController(_ nsViewController: VC, context: Context) {

    }
    func makeNSViewController(context: Context) -> VC {
        let gameOn = GameViewController(client: client)
        return gameOn
    }
    #else
    func updateUIViewController(_ uiViewController: VC, context: Context) {
        // later
    }
    func makeUIViewController(context: Context) -> VC {
        let gameOn = GameViewController(client: client)
        return gameOn
    }
    #endif
}
