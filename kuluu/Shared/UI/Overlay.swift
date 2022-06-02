//
//  Overlay.swift
//  kuluu (iOS)
//
//  Created by kuluu-jon on 5/16/22.
//

import Foundation
import SceneKit
import SpriteKit

class Overlay: SKScene {
    private var overlayNode: SKNode
    private var congratulationsGroupNode: SKNode?
//    private var collectedKeySprite: SKSpriteNode!
//    private var collectedGemsSprites = [SKSpriteNode]()
    
    // demo UI
    private var demoMenu: Menu?
    
#if os( iOS )
    public var controlOverlay: ControlOverlay?
#endif
    
    // MARK: - Initialization
    // hello
    init(size: CGSize, controller: GameController) {
        overlayNode = SKNode()
        overlayNode.name = "Overlay"
        super.init(size: size)
        
        let w: CGFloat = size.width
        let h: CGFloat = size.height
        
//        collectedGemsSprites = []
        
        // Setup the game overlays using SpriteKit.
        #if os(iOS)
        scaleMode = .aspectFit
        #else
        scaleMode = .aspectFill
        #endif
        
        addChild(overlayNode)
        overlayNode.position = CGPoint(x: 0.0, y: h)
        
        
        // The virtual D-pad
#if os( iOS )
        controlOverlay = ControlOverlay(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: w, height: h))
        controlOverlay!.leftPad.delegate = controller
        controlOverlay!.rightPad.delegate = controller
        controlOverlay!.buttonA.delegate = controller
        controlOverlay!.buttonB.delegate = controller
        addChild(controlOverlay!)
#endif
        // the demo UI
        demoMenu = Menu(size: size)
        demoMenu!.delegate = controller as? MenuDelegate
        demoMenu!.isHidden = true
        overlayNode.addChild(demoMenu!)
        
        // Assign the SpriteKit overlay to the SceneKit view.
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layout2DOverlay() {
        overlayNode.position = CGPoint(x: 0.0, y: size.height)
        
        guard let congratulationsGroupNode = self.congratulationsGroupNode else { return }
        
        congratulationsGroupNode.position = CGPoint(x: CGFloat(size.width * 0.5), y: CGFloat(size.height * 0.5))
        congratulationsGroupNode.xScale = 1.0
        congratulationsGroupNode.yScale = 1.0
        let currentBbox: CGRect = congratulationsGroupNode.calculateAccumulatedFrame()
        
        let margin: CGFloat = 25.0
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let maximumAllowedBbox: CGRect = bounds.insetBy(dx: margin, dy: margin)
        
        let top: CGFloat = currentBbox.maxY - congratulationsGroupNode.position.y
        let bottom: CGFloat = congratulationsGroupNode.position.y - currentBbox.minY
        let maxTopAllowed: CGFloat = maximumAllowedBbox.maxY - congratulationsGroupNode.position.y
        let maxBottomAllowed: CGFloat = congratulationsGroupNode.position.y - maximumAllowedBbox.minY
        
        let `left`: CGFloat = congratulationsGroupNode.position.x - currentBbox.minX
        let `right`: CGFloat = currentBbox.maxX - congratulationsGroupNode.position.x
        let maxLeftAllowed: CGFloat = congratulationsGroupNode.position.x - maximumAllowedBbox.minX
        let maxRightAllowed: CGFloat = maximumAllowedBbox.maxX - congratulationsGroupNode.position.x
        
        let topScale: CGFloat = top > maxTopAllowed ? maxTopAllowed / top: 1
        let bottomScale: CGFloat = bottom > maxBottomAllowed ? maxBottomAllowed / bottom: 1
        let leftScale: CGFloat = `left` > maxLeftAllowed ? maxLeftAllowed / `left`: 1
        let rightScale: CGFloat = `right` > maxRightAllowed ? maxRightAllowed / `right`: 1
        
        let scale: CGFloat = min(topScale, min(bottomScale, min(leftScale, rightScale)))
        
        congratulationsGroupNode.xScale = scale
        congratulationsGroupNode.yScale = scale
    }
    
    var collectedGemsCount: Int = 0 {
        didSet {
//            collectedGemsSprites[collectedGemsCount - 1].texture = SKTexture(imageNamed:"collectableBIG_full.png")
//
//            collectedGemsSprites[collectedGemsCount - 1].run(SKAction.sequence([
//                SKAction.wait(forDuration: 0.5),
//                SKAction.scale(by: 1.5, duration: 0.2),
//                SKAction.scale(by: 1 / 1.5, duration: 0.2)
//            ]))
        }
    }
    
    func didCollectKey() {
//        collectedKeySprite.texture = SKTexture(imageNamed:"key_full.png")
//        collectedKeySprite.run(SKAction.sequence([
//            SKAction.wait(forDuration: 0.5),
//            SKAction.scale(by: 1.5, duration: 0.2),
//            SKAction.scale(by: 1 / 1.5, duration: 0.2)
//        ]))
    }
    
#if os( iOS )
    func showVirtualPad() {
        controlOverlay!.isHidden = false
    }
    
    func hideVirtualPad() {
        controlOverlay!.isHidden = true
    }
#endif
    
    // MARK: Congratulate the player
    
    func showEndScreen() {
        // Congratulation title
        let congratulationsNode = SKSpriteNode(imageNamed: "congratulations.png")
        
        // Max image
        let characterNode = SKSpriteNode(imageNamed: "congratulations_pandaMax.png")
        characterNode.position = CGPoint(x: CGFloat(0.0), y: CGFloat(-220.0))
        characterNode.anchorPoint = CGPoint(x: CGFloat(0.5), y: CGFloat(0.0))
        
        congratulationsGroupNode = SKNode()
        congratulationsGroupNode!.addChild(characterNode)
        congratulationsGroupNode!.addChild(congratulationsNode)
        addChild(congratulationsGroupNode!)
        
        // Layout the overlay
        layout2DOverlay()
        
        // Animate
        congratulationsNode.alpha = 0.0
        congratulationsNode.xScale = 0.0
        congratulationsNode.yScale = 0.0
        congratulationsNode.run( SKAction.group([SKAction.fadeIn(withDuration: 0.25),
                                                 SKAction.sequence([SKAction.scale(to: 1.22, duration: 0.25),
                                                                    SKAction.scale(to: 1.0, duration: 0.1)])]))
        
        characterNode.alpha = 0.0
        characterNode.xScale = 0.0
        characterNode.yScale = 0.0
        characterNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                             SKAction.group([SKAction.fadeIn(withDuration: 0.5),
                                                             SKAction.sequence([SKAction.scale(to: 1.22, duration: 0.25),
                                                                                SKAction.scale(to: 1.0, duration: 0.1)])])]))
    }
    
    @objc
    func toggleMenu(_ sender: SKButton) {
        demoMenu!.isHidden = !demoMenu!.isHidden
    }
}
