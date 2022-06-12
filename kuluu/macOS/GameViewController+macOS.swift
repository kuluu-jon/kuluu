//
//  GameViewController+macOS.swift
//  kuluu (iOS)
//
//  Created by kuluu-jon on 5/16/22.
//

import AppKit
import SceneKit
import kuluu_ffxi_network_protocol
import GameController
import SwiftUI

class GameViewController: VC {

    private let client: FFXIClient
    // FIXME: try using SpriteKit overlay and SK3DNode that renders instead. might be more performant...
    private lazy var minimap: SCNView = {
        let minimap = SCNView(frame: .zero)
        minimap.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(minimap)
        minimap.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        minimap.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8).isActive = true
        minimap.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        minimap.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        minimap.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
//        minimap.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
//        let approxFps = (0.5 * Double(gameView.preferredFramesPerSecond)).rounded()
        minimap.preferredFramesPerSecond = 15// Int(approxFps != 0 ? approxFps : 4)
        minimap.antialiasingMode = .none
        minimap.usesReverseZ = true
        minimap.rendersContinuously = false
        minimap.backgroundColor = .clear
        minimap.allowsCameraControl = true
        minimap.showsStatistics = true
        return minimap
    }()

    var gameView: SCNView {
        return self.view as! SCNView
    }

    private var gameController: GameController!

    required init?(coder: NSCoder) {
        fatalError("just say 'NO!~' uwu to storyboards")
    }

    init(client: FFXIClient) {
        self.client = client
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        let view: SCNView = {
            let view: GameSCNView = .init()
            view.delegate = self
            view.viewController = self
            view.isTemporalAntialiasingEnabled = false
            view.isJitteringEnabled = false
            return view
        }()
        self.view = view
        _ = minimap
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gameController = GameController(sceneRenderer: gameView, minimapRenderer: minimap, ffxiClient: client)

        minimap.isHidden = gameController.isMinimapHidden

        //        self.gameController.setCharacter(name: self.selectedCharacter.zoneIp + ":\( self.selectedCharacter.zonePort)")

        // Allow the user to manipulate the camera
        //        self.gameView.allowsCameraControl = true

        // Show statistics such as fps and timing information
        self.gameView.showsStatistics = true

        // Configure the view
        self.gameView.backgroundColor = NSColor.black

        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = gameView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        self.gameView.gestureRecognizers = gestureRecognizers
    }

    @objc func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // Highlight the clicked nodes
        let p = gestureRecognizer.location(in: gameView)
//        gameController.highlightNodes(atPoint: p)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.becomeFirstResponder()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        minimap.layer?.contentsScale = 0.5
        minimap.layer?.opacity = 0.78
    }

    func keyDown(_ view: NSView, event theEvent: NSEvent) -> Bool {
        var characterDirection = self.gameController!.characterDirection
        var cameraDirection = self.gameController!.cameraDirection
        var cameraDistance = self.gameController.cameraDistanceModifier

        var updateCamera = false
        var updateCharacter = false

        func moveLeft() {
            // Left
            if !theEvent.isARepeat {
                characterDirection.x -= 1
                updateCharacter = true
            }
        }

        func moveRight() {
            // Right
            if !theEvent.isARepeat {
                characterDirection.x += 1
                updateCharacter = true
            }
        }

        func moveUp() {

            // Up
            if !theEvent.isARepeat {
                characterDirection.y -= 1
                updateCharacter = true
            }
        }

        func moveDown() {
            gameController.isAutoMove = false
            // Down
            if !theEvent.isARepeat {
                characterDirection.y += 1
                updateCharacter = true
            }
        }

        func cameraLeft() {
            // Camera Left
            if !theEvent.isARepeat {
                cameraDirection.x -= 1
                updateCamera = true
            }
        }

        func cameraRight() {

            // Camera Right
            if !theEvent.isARepeat {
                cameraDirection.x += 1
                updateCamera = true
            }
        }

        func cameraUp() {

            // Camera Up
            if !theEvent.isARepeat {
                cameraDirection.y -= 0.5
                updateCamera = true
            }
        }

        func cameraDown() {

            // Camera Down
            if !theEvent.isARepeat {
                cameraDirection.y += 0.5
                updateCamera = true
            }
        }

        func cameraIn() {
            cameraDistance += 0.5
            updateCamera = true
        }

        func cameraOut() {
            cameraDistance -= 0.5
            updateCamera = true
        }

        guard let kc = theEvent.keyboardKey else {
            assertionFailure("unhandled key")
            print("unhandled key: \(theEvent.keyCode)")
            return false
        }
        switch kc {
        case .r:
            gameController.isAutoMove.toggle()
            if !gameController.isAutoMove {
                characterDirection = .zero
                updateCharacter = true
            }
        case .downArrow: cameraDown()
        case .upArrow: cameraUp()
        case .leftArrow: cameraRight()
        case .rightArrow: cameraLeft()
        case .w: moveUp()
        case .s: moveDown()
        case .a where !gameController.isAutoMove: moveLeft()
        case .a where gameController.isAutoMove: cameraRight()
        case .d where !gameController.isAutoMove: moveRight()
        case .d where gameController.isAutoMove: cameraLeft()
        case .m where !theEvent.isARepeat:
            gameController.isMinimapHidden.toggle()
            minimap.isHidden = gameController.isMinimapHidden
//            if minimap.isHidden {
//                minimap.scene = nil
//            } else {
//                minimap.scene = gameView.scene
            minimap.isPlaying = !minimap.isHidden
//            }
        case .period: cameraIn()
        case .comma: cameraOut()
        case .space:
            if !theEvent.isARepeat {
                gameController!.controllerJump(true)
            }
        default: return false
        }

        if updateCharacter {
            gameController.isAutoMove = false
            gameController?.characterDirection =
                characterDirection.allZero()
                    ? characterDirection
                    : simd_normalize(characterDirection)
        }

        if updateCamera {
            gameController?.cameraDirection =
                cameraDirection.allZero()
                    ? cameraDirection
                    : simd_normalize(cameraDirection)
            gameController?.cameraDistanceModifier = cameraDistance
        }

        return true
    }

    func keyUp(_ view: NSView, event theEvent: NSEvent) -> Bool {
        var characterDirection = gameController!.characterDirection
        var cameraDirection = gameController!.cameraDirection

        var updateCamera = false
        var updateCharacter = false

        func moveLeft() {
            guard !gameController.isAutoMove else {
                updateCharacter = true
                return
            }
            // Left
            if !theEvent.isARepeat && characterDirection.x < 0 {
                characterDirection.x = 0 // FIXME: not quite right for multi-keypress, should add, for all of these
                updateCharacter = true
            }
        }

        func moveRight() {
            guard !gameController.isAutoMove else {
                updateCharacter = true
                return
            }
            // Right
            if !theEvent.isARepeat && characterDirection.x > 0 {
                characterDirection.x = 0
                updateCharacter = true
            }
        }

        func moveUp() {
            guard !gameController.isAutoMove else {
                updateCharacter = true
                return
            }
            // Up
            if !theEvent.isARepeat && characterDirection.y < 0 {
                characterDirection.y = 0
                updateCharacter = true
            }
        }
        func moveDown() {
            // Down
            if !theEvent.isARepeat && characterDirection.y > 0 {
                characterDirection.y = 0
                updateCharacter = true
            }
        }

        func cameraRight() {
            // Camera Right
            if !theEvent.isARepeat && cameraDirection.x > 0 {
                cameraDirection.x = 0
                updateCamera = true
            }
        }

        func cameraLeft() {
            // Camera Left
            if !theEvent.isARepeat && cameraDirection.x < 0 {
                cameraDirection.x = 0
                updateCamera = true
            }

        }
        func cameraUp() {
            // Camera Up
            if !theEvent.isARepeat && cameraDirection.y < 0 {
                cameraDirection.y = 0
                updateCamera = true
            }
        }

        func cameraDown() {
            // Camera Down
            if !theEvent.isARepeat && cameraDirection.y > 0 {
                cameraDirection.y = 0
                updateCamera = true
            }
        }

        func cameraIn() {
//            gameController.cameraDistanceModifier = 0
        }

        func cameraOut() {
//            gameController.cameraDistanceModifier = 0
        }

        guard let kc = theEvent.keyboardKey else {
            assertionFailure("unhandled key")
            print("unhandled key: \(theEvent.keyCode)")
            return false
        }
        switch kc {
        case .enter, .returnKey:
            if !theEvent.isARepeat {
                gameController!.resetPlayerPosition()
            }
            return true
        case .downArrow: cameraDown()
        case .upArrow: cameraUp()
        case .leftArrow: cameraRight()
        case .rightArrow: cameraLeft()
        case .w: moveUp()
        case .s: moveDown()
        case .a where !gameController.isAutoMove: moveLeft()
        case .a where gameController.isAutoMove: cameraRight()
        case .d where !gameController.isAutoMove: moveRight()
        case .d where gameController.isAutoMove: cameraLeft()
        case .period: cameraIn()
        case .comma: cameraOut()
        case .space:
            // Space
            if !theEvent.isARepeat {
                gameController!.controllerJump(false)
            }
            return true
        default:
            break
        }

        if updateCharacter {
            self.gameController?.characterDirection = characterDirection.allZero() ? characterDirection: simd_normalize(characterDirection)
            return true
        }

        if updateCamera {
            self.gameController?.cameraDirection = cameraDirection.allZero() ? cameraDirection: simd_normalize(cameraDirection)
            return true
        }

        return false
    }
}

extension GameViewController: SCNSceneRendererDelegate {

}

class GameSCNView: SCNView {
    weak var viewController: GameViewController?

    // MARK: - EventHandler

    override func keyDown(with theEvent: NSEvent) {
        if viewController?.keyDown(self, event: theEvent) == false {
            super.keyDown(with: theEvent)
        }
    }

    override func keyUp(with theEvent: NSEvent) {
        if viewController?.keyUp(self, event: theEvent) == false {
            super.keyUp(with: theEvent)
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
    }

    override func viewDidMoveToWindow() {
        // fuddle w/ @1x, 2x, 3x, etc. retina/contentsScale
        layer?.contentsScale = window?.backingScaleFactor ?? 2
    }
}
