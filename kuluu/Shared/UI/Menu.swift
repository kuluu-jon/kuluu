//
//  Menu.swift
//  kuluu (iOS)
//
//  Created by kuluu-jon on 5/16/22.
//

import SpriteKit

protocol MenuDelegate: NSObjectProtocol {
    
    func fStopChanged(_ value: CGFloat)
    func focusDistanceChanged(_ value: CGFloat)
    func debugMenuSelectCameraAtIndex(_ index: Int)
}

class Menu: SKNode {
    weak var delegate: MenuDelegate?
    
    var cameraButtons = [SKButton]()
    var dofSliders = [Slider]()
    var isMenuHidden: Bool = false
    
    let buttonMargin = CGFloat(250)
    let menuY = CGFloat(40)
    let duration = 0.3
    
    init(size: CGSize) {
        super.init()
        
        // Track mouse event
        isUserInteractionEnabled = true
        
        // Camera buttons
        do {
            let buttonLabels = ["Camera 1", "Camera 2", "Camera 3"]
            cameraButtons = buttonLabels.map { return SKButton(text:$0) }
            
            for (i, button) in cameraButtons.enumerated() {
                let x: CGFloat = button.width / 2 + (i > 0 ? cameraButtons[i - 1].position.x + cameraButtons[i - 1].width / 2 + 10: buttonMargin)
                let y: CGFloat = size.height - menuY
                button.position = CGPoint(x: x, y: y)
                button.setClickedTarget(self, action: #selector(self.menuChanged))
                addChild(button)
            }
        }
        // Depth of Field
        do {
            let buttonLabels = ["fStop", "Focus"]
            dofSliders = buttonLabels.map { return Slider(width: 300, height: 10, text:$0) }
            
            for (i, slider) in dofSliders.enumerated() {
                slider.position = CGPoint(x: buttonMargin, y: CGFloat(size.height - CGFloat(i) * 30.0 - 70.0))
                slider.alpha = 0.0
                self.addChild(slider)
            }
            dofSliders[0].setClickedTarget(self, action: #selector(self.cameraFStopChanged))
            dofSliders[1].setClickedTarget(self, action: #selector(self.cameraFocusDistanceChanged))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func menuChanged(_ sender: Any) {
        hideSlidersMenu()
        if let index = cameraButtons.index(of: sender as! SKButton) {
            self.delegate?.debugMenuSelectCameraAtIndex(index)
            if index == 2 {
                showSlidersMenu()
            }
        }
    }
    
    override var isHidden: Bool {
        get {
            return isMenuHidden
        }
        set {
            if newValue {
                hide()
            } else {
                show()
            }
        }
    }
    
    func show() {
        for button in cameraButtons {
            button.alpha = 0.0
            button.run(SKAction.fadeIn(withDuration: duration))
        }
        isMenuHidden = false
    }
    
    func hide() {
        for button in cameraButtons {
            button.alpha = 1.0
            button.run(SKAction.fadeOut(withDuration: duration))
        }
        hideSlidersMenu()
        isMenuHidden = true
    }
    
    func hideSlidersMenu() {
        for slider in dofSliders {
            slider.run(SKAction.fadeOut(withDuration: duration))
        }
    }
    
    func showSlidersMenu() {
        for slider in dofSliders {
            slider.run(SKAction.fadeIn(withDuration: duration))
        }
        dofSliders[0].value = 0.1
        dofSliders[1].value = 0.5
        perform(#selector(self.cameraFStopChanged), with: dofSliders[0])
        perform(#selector(self.cameraFocusDistanceChanged), with: dofSliders[1])
    }
    
    @IBAction func cameraFStopChanged(_ sender: Any) {
        if let method = delegate?.fStopChanged {
            method(dofSliders[0].value + 0.2)
        }
    }
    
    @IBAction func cameraFocusDistanceChanged(_ sender: Any) {
        if let method = delegate?.focusDistanceChanged {
            method(dofSliders[1].value * 20.0 + 3.0)
        }
    }
}


import SpriteKit

class Slider: SKNode {
    var value: CGFloat = 0.0 {
        didSet {
            slider!.position = CGPoint(x: CGFloat(background!.position.x + value * width ), y: CGFloat(0.0))
        }
    }
    
    var label: SKLabelNode?
    var slider: SKShapeNode?
    var background: SKSpriteNode?
    private(set) var actionClicked: Selector?
    private(set) var targetClicked: AnyObject?
    
    init(width: Int, height: Int, text txt: String) {
        super.init()
        
        // create a label
        let fontName: String = "Optima-ExtraBlack"
        label = SKLabelNode(fontNamed: fontName)
        label!.text = txt
        label!.fontSize = 18
        label!.fontColor = SKColor.white
        label!.position = CGPoint(x: 0.0, y: -8.0)
        
        // create background & slider
        background = SKSpriteNode(color: SKColor.white, size: CGSize(width: CGFloat(width), height: CGFloat(2)))
        slider = SKShapeNode(circleOfRadius: CGFloat( height ) )
        slider!.fillColor = SKColor.white
        background!.anchorPoint = CGPoint(x: CGFloat(0.0), y: CGFloat(0.5))
        
        slider!.position = CGPoint(x: CGFloat(label!.frame.size.width / 2.0 + 15), y: CGFloat(0.0))
        background!.position = CGPoint(x: CGFloat(label!.frame.size.width / 2.0 + 15), y: CGFloat(0.0))
        
        // add to the root node
        addChild(label!)
        addChild(background!)
        addChild(slider!)
        
        // track mouse event
        isUserInteractionEnabled = true
        value = 0.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var width: CGFloat {
        return background!.frame.size.width
    }
    
    var height: CGFloat {
        return slider!.frame.size.height
    }
    
    func setBackgroundColor(_ col: SKColor) {
        background!.color = col
    }
    
    func setClickedTarget(_ target: AnyObject, action: Selector) {
        targetClicked = target
        actionClicked = action
    }
    
#if os( OSX )
    override func mouseDown(with event: NSEvent) {
        mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        setBackgroundColor(SKColor.white)
    }
    
    override func mouseDragged(with event: NSEvent) {
        setBackgroundColor(SKColor.gray)
        
        let posInView = scene!.convert(position, from:parent!)
        
        let x = event.locationInWindow.x - posInView.x - background!.position.x
        let pos = fmax(fmin(x, width), 0.0)
        slider!.position = CGPoint(x: CGFloat(background!.position.x + pos), y: 0.0)
        value = pos / width
        _ = targetClicked?.perform(actionClicked, with: self)
    }
    
#endif
#if os( iOS )
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setBackgroundColor(SKColor.gray)
        let x = touches.first!.location(in: self).x - background!.position.x
        let pos = max(fmin(x, width), 0.0)
        
        slider!.position = CGPoint(x: CGFloat(background!.position.x + pos), y: CGFloat(0.0))
        value = pos / width
        _ = targetClicked!.perform(actionClicked, with: self)
    }
#endif
}


class SKButton: SKNode {
    var width: CGFloat {
        return size.width
    }
    
    var label: SKLabelNode?
    var background: SKSpriteNode?
    private(set) var actionClicked: Selector?
    private(set) var targetClicked: Any?
    var size = CGSize.zero
    
    func setText(_ txt: String) {
        label!.text = txt
    }
    
    func setBackgroundColor(_ col: SKColor) {
        guard let background = background else { return }
        background.color = col
    }
    
    func setClickedTarget(_ target: Any, action: Selector) {
        targetClicked = target
        actionClicked = action
    }
    
    init(text txt: String) {
        super.init()
        
        // create a label
        let fontName: String = "Optima-ExtraBlack"
        label = SKLabelNode(fontNamed: fontName)
        label!.text = txt
        label!.fontSize = 18
        label!.fontColor = SKColor.white
        label!.position = CGPoint(x: CGFloat(0.0), y: CGFloat(-8.0))
        
        // create the background
        size = CGSize(width: CGFloat(label!.frame.size.width + 10.0), height: CGFloat(30.0))
        background = SKSpriteNode(color: SKColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.75)), size: size)
        
        // add to the root node
        addChild(background!)
        addChild(label!)
        
        // Track mouse event
        isUserInteractionEnabled = true
    }
    
    init(skNode node: SKNode) {
        super.init()
        
        // Track mouse event
        isUserInteractionEnabled = true
        size = node.frame.size
        addChild(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func height() -> CGFloat {
        return size.height
    }
    
#if os( OSX )
    override func mouseDown(with event: NSEvent) {
        setBackgroundColor(SKColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(1.0)))
    }
    
    override func mouseUp(with event: NSEvent) {
        setBackgroundColor(SKColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.75)))
        
        let x = position.x + ((parent?.position.x) ?? CGFloat(0))
        let y = position.y + ((parent?.position.y) ?? CGFloat(0))
        let p = event.locationInWindow
        
        if fabs(p.x - x) < width / 2 * xScale && fabs(p.y - y) < height() / 2 * yScale {
            _ = (targetClicked! as AnyObject).perform(actionClicked, with: self)
        }
    }
    
#endif
#if os( iOS )
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = (targetClicked! as AnyObject).perform(actionClicked, with: self)
    }
#endif
}
