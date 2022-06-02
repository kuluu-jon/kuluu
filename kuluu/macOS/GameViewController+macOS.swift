//
//  GameViewController+macOS.swift
//  kuluu (iOS)
//
//  Created by kuluu-jon on 5/16/22.
//

import AppKit
import SceneKit
import Networking

class GameViewController: VC {
    
    private let client: FFXIClient
    
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
            return view
        }()
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gameController = GameController(sceneRenderer: gameView, ffxiClient: client)
        
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
    
    
    func keyDown(_ view: NSView, event theEvent: NSEvent) -> Bool {
        var characterDirection = self.gameController!.characterDirection
        var cameraDirection = self.gameController!.cameraDirection
        
        var updateCamera = false
        var updateCharacter = false
        
        func moveLeft() {
            // Left
            if !theEvent.isARepeat {
                characterDirection.x = -1
                updateCharacter = true
            }
        }
        
        func moveRight() {
            // Right
            if !theEvent.isARepeat {
                characterDirection.x = 1
                updateCharacter = true
            }
        }
        
        func moveUp() {
            
            // Up
            if !theEvent.isARepeat {
                characterDirection.y = -1
                updateCharacter = true
            }
        }
        
        func moveDown() {
            // Down
            if !theEvent.isARepeat {
                characterDirection.y = 1
                updateCharacter = true
            }
        }
        
        func cameraLeft() {
            // Camera Left
            if !theEvent.isARepeat {
                cameraDirection.x = -1
                updateCamera = true
            }
        }
        
        func cameraRight() {
            
            // Camera Right
            if !theEvent.isARepeat {
                cameraDirection.x = 1
                updateCamera = true
            }
        }
        
        func cameraUp() {
            
            // Camera Up
            if !theEvent.isARepeat {
                cameraDirection.y = -1
                updateCamera = true
            }
        }
        
        func cameraDown() {
            
            // Camera Down
            if !theEvent.isARepeat {
                cameraDirection.y = 1
                updateCamera = true
            }
        }
        
        switch theEvent.keyCode {
        case 126: cameraDown()
        case 125: cameraUp()
        case 123: cameraRight()
        case 124: cameraLeft()
        case 13: moveUp()
        case 1: moveDown()
        case 0: // d?
            moveLeft()
        case 2: // a?
            moveRight()
        case 49:
            // Space
            if !theEvent.isARepeat {
                gameController!.controllerJump(true)
            }
            return true
        case 8:
            // c
            if !theEvent.isARepeat {
                gameController!.controllerAttack()
            }
            return true
        default:
            return false
        }
        
        if updateCharacter {
            self.gameController?.characterDirection = characterDirection.allZero() ? characterDirection: simd_normalize(characterDirection)
        }
        
        if updateCamera {
            self.gameController?.cameraDirection = cameraDirection.allZero() ? cameraDirection: simd_normalize(cameraDirection)
        }
        
        return true
    }
    
    func keyUp(_ view: NSView, event theEvent: NSEvent) -> Bool {
        var characterDirection = gameController!.characterDirection
        var cameraDirection = gameController!.cameraDirection
        
        var updateCamera = false
        var updateCharacter = false
        
        func moveLeft() {
            // Left
            if !theEvent.isARepeat && characterDirection.x < 0 {
                characterDirection.x = 0
                updateCharacter = true
            }
        }
        
        func moveRight() {
            // Right
            if !theEvent.isARepeat && characterDirection.x > 0 {
                characterDirection.x = 0
                updateCharacter = true
            }
        }
        
        func moveUp() {
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
        
        switch theEvent.keyCode {
        case 36:
            if !theEvent.isARepeat {
                gameController!.resetPlayerPosition()
            }
            return true
        case 126: cameraDown()
        case 125: cameraUp()
        case 123: cameraRight()
        case 124: cameraLeft()
        case 13: moveUp()
        case 1: moveDown()
        case 0: moveLeft()
        case 2: moveRight()
        case 49:
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
        (overlaySKScene as? Overlay)?.layout2DOverlay()
    }
    
    override func viewDidMoveToWindow() {
        //disable retina
        layer?.contentsScale = window?.backingScaleFactor ?? 2
    }
}
