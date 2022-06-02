//
//  GameViewController+iOS.swift
//  kuluu (iOS)
//
//  Created by kuluu-jon on 5/16/22.
//

import UIKit
import SceneKit
import Networking

class GameViewController: UIViewController {
    
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
            view.viewController = self
            return view
        }()
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1.3x on iPads
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.gameView.contentScaleFactor = min(1.3, self.gameView.contentScaleFactor)
            self.gameView.preferredFramesPerSecond = 60
        }
                
        // Configure the view
        gameView.backgroundColor = UIColor.black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if gameController == nil {
            gameController = GameController(sceneRenderer: gameView, ffxiClient: client)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.landscapeLeft, .landscapeRight]
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        presses.first?.key.map(keyPressed)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        presses.first?.key.map(keyReleased)
    }
    
    override func pressesCancelled(_ presses: Set<UIPress>,
                                   with event: UIPressesEvent?) {
        super.pressesCancelled(presses, with: event)
        presses.first?.key.map(keyReleased)
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    override var shouldAutorotate: Bool { return true }
}

private extension GameViewController {
    
    func keyPressed(_ key: UIKey) {
        var characterDirection = self.gameController!.characterDirection
        var cameraDirection = self.gameController!.cameraDirection
        
        var updateCamera = false
        var updateCharacter = false
        
        func moveLeft() {
            // Left
//            if !theEvent.isARepeat {
                characterDirection.x = -1
                updateCharacter = true
//            }
        }
        
        func moveRight() {
            // Right
//            if !theEvent.isARepeat {
                characterDirection.x = 1
                updateCharacter = true
//            }
        }
        
        func moveUp() {
            
            // Up
//            if !theEvent.isARepeat {
                characterDirection.y = -1
                updateCharacter = true
//            }
        }
        
        func moveDown() {
            // Down
//            if !theEvent.isARepeat {
                characterDirection.y = 1
                updateCharacter = true
//            }
        }
        
        func cameraLeft() {
            // Camera Left
//            if !theEvent.isARepeat {
                cameraDirection.x = -1
                updateCamera = true
//            }
        }
        
        func cameraRight() {
            
            // Camera Right
//            if !theEvent.isARepeat {
                cameraDirection.x = 1
                updateCamera = true
//            }
        }
        
        func cameraUp() {
            
            // Camera Up
//            if !theEvent.isARepeat {
                cameraDirection.y = -1
                updateCamera = true
//            }
        }
        
        func cameraDown() {
            
            // Camera Down
//            if !theEvent.isARepeat {
                cameraDirection.y = 1
                updateCamera = true
//            }
        }
        
        switch key.keyCode {
        case .keyboardW: moveUp()
        case .keyboardS: moveDown()
        case .keyboardA: moveLeft()
        case .keyboardD: moveRight()
        case .keyboardUpArrow: cameraDown()
        case .keyboardDownArrow: cameraUp()
        case .keyboardLeftArrow: cameraRight()
        case .keyboardRightArrow: cameraLeft()
        default:
            break
        }
        
        if updateCharacter {
            self.gameController?.characterDirection = characterDirection.allZero() ? characterDirection: simd_normalize(characterDirection)
        }
        
        if updateCamera {
            self.gameController?.cameraDirection = cameraDirection.allZero() ? cameraDirection: simd_normalize(cameraDirection)
        }
    }
    
    func keyReleased(_ key: UIKey) {
        var characterDirection = gameController!.characterDirection
        var cameraDirection = gameController!.cameraDirection
        
        var updateCamera = false
        var updateCharacter = false
        
        func moveLeft() {
            // Left
            if characterDirection.x < 0 {
                characterDirection.x = 0
                updateCharacter = true
            }
        }
        
        func moveRight() {
            // Right
            if characterDirection.x > 0 {
                characterDirection.x = 0
                updateCharacter = true
            }
        }
        
        func moveUp() {
            // Up
            if characterDirection.y < 0 {
                characterDirection.y = 0
                updateCharacter = true
            }
        }
        func moveDown() {
            // Down
            if characterDirection.y > 0 {
                characterDirection.y = 0
                updateCharacter = true
            }
        }
        
        func cameraRight() {
            
            // Camera Right
            if cameraDirection.x > 0 {
                cameraDirection.x = 0
                updateCamera = true
            }
        }
        
        func cameraLeft() {
            // Camera Left
            if cameraDirection.x < 0 {
                cameraDirection.x = 0
                updateCamera = true
            }
            
        }
        func cameraUp() {
            // Camera Up
            if cameraDirection.y < 0 {
                cameraDirection.y = 0
                updateCamera = true
            }
        }
        
        func cameraDown() {
            // Camera Down
            if cameraDirection.y > 0 {
                cameraDirection.y = 0
                updateCamera = true
            }
        }
        
        switch key.keyCode {
        case .keyboardW: moveUp()
        case .keyboardS: moveDown()
        case .keyboardA: moveLeft()
        case .keyboardD: moveRight()
        case .keyboardUpArrow: cameraDown()
        case .keyboardDownArrow: cameraUp()
        case .keyboardLeftArrow: cameraRight()
        case .keyboardRightArrow: cameraLeft()
        default:
            break
        }
        
        if updateCharacter {
            self.gameController?.characterDirection = characterDirection.allZero() ? characterDirection: simd_normalize(characterDirection)
        }
        
        if updateCamera {
            self.gameController?.cameraDirection = cameraDirection.allZero() ? cameraDirection: simd_normalize(cameraDirection)
        }
    }
}

class GameSCNView: SCNView {
    weak var viewController: GameViewController?
    
    // MARK: - EventHandler
    
//    override func keyDown(with theEvent: NSEvent) {
//        if viewController?.keyDown(self, event: theEvent) == false {
//            super.keyDown(with: theEvent)
//        }
//    }
//
//    override func keyUp(with theEvent: NSEvent) {
//        if viewController?.keyUp(self, event: theEvent) == false {
//            super.keyUp(with: theEvent)
//        }
//    }
//
//    override func setFrameSize(_ newSize: NSSize) {
//        super.setFrameSize(newSize)
//    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        (overlaySKScene as? Overlay)?.layout2DOverlay()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        layer.contentsScale = 2
    }
    
//    override func viewDidMoveToWindow() {
//        //disable retina
//        layer?.contentsScale = window?.backingScaleFactor ?? 2
//    }
}
