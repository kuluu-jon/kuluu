//
//  GameController.swift
//  ffxi Shared
//
//  Created by kuluu-jon on 1/3/22.
//

import SceneKit
import SwiftUI
import kuluu_ffxi_network_protocol
import kuluu_ffxi_emulator

#if os(watchOS)
    import WatchKit
#endif

#if os(macOS)
    typealias SCNColor = NSColor
#else
    typealias SCNColor = UIColor
#endif

/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class serves as the app's source of control flow.
 */

import GameController
import GameplayKit
import SceneKit

// Collision bit masks
struct Bitmask: OptionSet {
    let rawValue: Int
    static let character = Bitmask(rawValue: 1 << 0) // the main character
    static let collision = Bitmask(rawValue: 1 << 1) // the ground and walls
    static let enemy = Bitmask(rawValue: 1 << 2) // the enemies
    static let trigger = Bitmask(rawValue: 1 << 3) // the box that triggers camera changes and other actions
    static let collectable = Bitmask(rawValue: 1 << 4) // the collectables (gems and key)
}

#if os( iOS )
typealias ExtraProtocols = SCNSceneRendererDelegate & SCNPhysicsContactDelegate & MenuDelegate & PadOverlayDelegate & ButtonOverlayDelegate
#else
typealias ExtraProtocols = SCNSceneRendererDelegate & SCNPhysicsContactDelegate
#endif

enum ParticleKind: Int {
    case collect = 0
    case collectBig
    case keyApparition
    case enemyExplosion
    case unlockDoor
    case totalCount
}

enum AudioSourceKind: Int {
    case collect = 0
    case collectBig
    case unlockDoor
    case hitEnemy
    case totalCount
}
class GameController: NSObject, ExtraProtocols {
    private let client: FFXIClient

    // Global settings
    static let defaultCameraTransitionDuration = 1.0
    static let cameraOrientationSensitivity: Float = .pi / 100 // just being cheeky

    private var scene: SCNScene?
    private weak var sceneRenderer: SCNSceneRenderer?
    private weak var minimapRenderer: SCNSceneRenderer?

    struct Map {
        let visible: SCNNode
        let collisions: SCNNode
        let navigation: GKGraph
    }

    private var map: Map? {
        didSet {
            guard map?.collisions.hash != oldValue?.collisions.hash else {
                return
            }
            setupPhysics()
        }
    }

    // Character
    private var character: Character? {
        didSet {
            character?.collisions = map?.collisions
        }
    }

    // Camera and targets
    private var activeCameraNode = SCNNode()
    private var minimapCamera: SCNNode?
    private var cameraAltitude: Float = 2
    private var lookAtTarget = SCNNode()
    private var lastActiveCamera: SCNNode?
    private var lastActiveCameraFrontDirection = simd_float3.zero
    private var activeCamera: SCNNode? {
        didSet {
            let textLookAtConstraint = SCNLookAtConstraint(target: activeCamera)
            textLookAtConstraint.influenceFactor = 1
            textLookAtConstraint.isGimbalLockEnabled = true

            let keepAltitude = SCNTransformConstraint.positionConstraint(inWorldSpace: true, with: {(_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
                var position = SIMD3<Float>(self.character!.node.position)
                position.y = self.character!.baseAltitude + 2
                return SCNVector3( position )
            })
            character?.titleNode.constraints = [textLookAtConstraint, keepAltitude]
        }
    }
    private var directLight: SCNNode?
    private var playingCinematic: Bool = false

    private var audioSources = [SCNAudioSource](repeatElement(SCNAudioSource(), count: AudioSourceKind.totalCount.rawValue))

    // GameplayKit
    private var gkScene: GKScene?

    // Game controller
    private var gamePadCurrent: GCController?
    private var gamePadLeft: GCControllerDirectionPad?
    private var gamePadRight: GCControllerDirectionPad?

    // update delta time
    private var lastUpdateTime = TimeInterval()
    private var lastSyncTime = TimeInterval() + 10

    // MARK: -
    // MARK: Setup

    func setupGameController() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.handleControllerDidConnect),
            name: NSNotification.Name.GCControllerDidConnect, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(self.handleControllerDidDisconnect),
            name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
        guard let controller = GCController.controllers().first else {
            return
        }
        registerGameController(controller)
    }

    func setupCharacter() {
        character = Character(scene: scene!)

        // keep a pointer to the physicsWorld from the character because we will need it when updating the character's position
        character!.physicsWorld = scene!.physicsWorld
        scene!.rootNode.addChildNode(character!.node!)

    }

    func setupPhysics() {
        // make sure all objects only collide with the character
        guard let map = map else {
            fatalError("no map to initialize physics on")
        }
        let physicsShape = SCNPhysicsShape(
            node: map.collisions,
            options: [
                .scale: self.map!.visible.scale,
                .type: SCNPhysicsShape.ShapeType.concavePolyhedron,
                .collisionMargin: Character.collisionMargin,
                .keepAsCompound: true
            ]
        )
        let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)

        physicsBody.categoryBitMask = 2
        physicsBody.collisionBitMask = Int(Bitmask.character.rawValue)
        map.visible.physicsBody = physicsBody
        map.collisions.enumerateChildNodes { node, _ in
            node.isHidden = true
            node.castsShadow = false
            node.geometry?.materials.forEach { $0.diffuse.contents = nil }
        }
        map.collisions.childNodes.first?.castsShadow = false
        map.collisions.childNodes.first?.isHidden = true
        map.collisions.isPaused = true
        map.collisions.castsShadow = false
        character?.collisions = map.visible
    }

    // the follow camera behavior make the camera to follow the character, with a constant distance, altitude and smoothed motion
    func setupFollowCamera(_ cameraNode: SCNNode) {
        // look at "lookAtTarget"

        let lookAtConstraint = SCNLookAtConstraint(target: self.lookAtTarget)
        lookAtConstraint.influenceFactor = 0.07
        lookAtConstraint.isGimbalLockEnabled = true

        // distance constraints
        let follow = SCNDistanceConstraint(target: self.lookAtTarget)
        let simdDistance = simd_length(cameraNode.simdPosition)

//
//        var simdDistance = simd_distance(self.lookAtTarget.simdWorldPosition, cameraNode.simdWorldPosition)
//        simdDistance -= (cameraDistanceModifier + abs(cameraDirection.y))
        let distance = CGFloat(simdDistance)
        let minD = CGFloat(2)
        let maxD = CGFloat(10)
        follow.minimumDistance = minD
        follow.maximumDistance = maxD// min(maxD, max(follow.minimumDistance, distance))
//
        let focusDistance = distance * 0.9
        cameraNode.camera?.focusDistance = focusDistance

        // configure a constraint to maintain a constant altitude relative to the character
        let desiredAltitude = abs(cameraNode.simdWorldPosition.y)
        weak var weakSelf = self

        let keepAltitude = SCNTransformConstraint.positionConstraint(inWorldSpace: true, with: {(_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in

            guard let strongSelf = weakSelf else { return position }
            if strongSelf.activeCamera != node {
                return position
            }
            var position = SIMD3<Float>(position)
            position.y = strongSelf.character!.baseAltitude + desiredAltitude
            return SCNVector3(position)
        })

        let accelerationConstraint = SCNAccelerationConstraint()
        accelerationConstraint.maximumLinearVelocity = 150.0
        accelerationConstraint.maximumLinearAcceleration = 50.0
        accelerationConstraint.decelerationDistance = 0.05
        accelerationConstraint.damping = 0.05

        // use a custom constraint to let the user orbit the camera around the character
        let transformNode = SCNNode()
        let orientationUpdateConstraint = SCNTransformConstraint(inWorldSpace: true) { [weak self] (_ node: SCNNode, _ transform: SCNMatrix4) -> SCNMatrix4 in
            guard let self = self else { return transform }
            if self.activeCamera != node {
                return transform
            }

            // Slowly update the acceleration constraint influence factor to smoothly reenable the acceleration.
            accelerationConstraint.influenceFactor = min(1, accelerationConstraint.influenceFactor + 0.01)

            let targetPosition = self.lookAtTarget.presentation.simdWorldPosition
            let cameraDirection = self.cameraDirection
            if cameraDirection.allZero() {
                return transform
            }

            // Disable the acceleration constraint.
            accelerationConstraint.influenceFactor = 0

            let characterWorldUp = self.character?.node?.presentation.simdWorldUp

            transformNode.transform = transform

            let q = simd_mul(
                simd_quaternion(Self.cameraOrientationSensitivity * cameraDirection.x, characterWorldUp!),
                simd_quaternion(Self.cameraOrientationSensitivity * cameraDirection.y, transformNode.simdWorldRight)
            )

            transformNode.simdRotate(by: q, aroundTarget: targetPosition)
            return transformNode.transform
        }

        cameraNode.constraints = [follow, keepAltitude, accelerationConstraint, orientationUpdateConstraint, lookAtConstraint]

    }

    func setupMinimapCamera(_ cameraNode: SCNNode) {
        // look at "lookAtTarget"

        let target = self.character!.node!

        let lookAtConstraint = SCNLookAtConstraint(target: target)
        lookAtConstraint.influenceFactor = 0.07
        lookAtConstraint.isGimbalLockEnabled = false

        // configure a constraint to maintain a constant altitude relative to the character

        let birdsEyeView = SCNTransformConstraint.positionConstraint(inWorldSpace: true, with: { [weak self] (_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
            guard let self = self else { return position }
            var position = SIMD3<Float>(target.simdWorldPosition)
            let box = self.map?.visible.boundingBox
            let width = abs((box?.max.x ?? 0) - (box?.min.x ?? 0))
            position.y += Float(width)
            self.minimapCamera?.camera?.automaticallyAdjustsZRange = true
//            self.minimapCamera?.camera?.zNear = Double(position.y - 15)
//            self.minimapCamera?.camera?.zFar = Double(position.y + 15)
//            self.minimapCamera?.camera?.orthographicScale = Double(10.0)
//            self.minimapCamera?.camera?.orthographicScale = Double(position.y / 10)
            return SCNVector3(position)
        })

        let accelerationConstraint = SCNAccelerationConstraint()
        accelerationConstraint.maximumLinearVelocity = 1500.0
        accelerationConstraint.maximumLinearAcceleration = 50.0
        accelerationConstraint.decelerationDistance = 0.05
        accelerationConstraint.damping = 0.05

        cameraNode.constraints = [birdsEyeView, lookAtConstraint]

    }

    func setupCameraNode(_ node: SCNNode) {
        guard let cameraName = node.name else { return }
        switch cameraName {
        case "camFollow": setupFollowCamera(node)
        case "camFollowMinimap": setupMinimapCamera(node)
        default: break
        }
    }

    func setupCamera() {
        // The lookAtTarget node will be placed slighlty above the character using a constraint
        weak var weakSelf = self

        lookAtTarget.name = "lookAtTarget"
        lookAtTarget.constraints = [ SCNTransformConstraint.positionConstraint(
            inWorldSpace: true, with: { (_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
                guard let strongSelf = weakSelf else { return position }

                guard var worldPosition = strongSelf.character?.node?.simdWorldPosition else { return position }
                worldPosition.y = strongSelf.character!.baseAltitude + 0.5
                return SCNVector3(worldPosition)
            })]

        scene?.rootNode.addChildNode(lookAtTarget)

        scene?.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            if node.camera != nil {
                self.setupCameraNode(node)
            }
        })

        activeCameraNode.camera = SCNCamera()
        activeCameraNode.name = "activeCamera"
        scene?.rootNode.addChildNode(activeCameraNode)

        minimapCamera = scene?.rootNode.childNode(withName: "camFollowMinimap", recursively: true)

        insertActiveCamera(into: "camFollow", animationDuration: 0.0)
    }

    func setupEnemies() {
//        self.enemy1 = self.scene?.rootNode.childNode(withName: "enemy1", recursively: true)
//        self.enemy2 = self.scene?.rootNode.childNode(withName: "enemy2", recursively: true)
//
        let gkScene = GKScene()
//
//        // Player
        let playerEntity = GKEntity()
        gkScene.addEntity(playerEntity)
        playerEntity.addComponent(GKSCNNodeComponent(node: character!.node))
//
        let playerComponent = PlayerComponent()
        playerComponent.isAutoMoveNode = false
        playerComponent.character = self.character
        playerEntity.addComponent(playerComponent)
        playerComponent.positionAgentFromNode()

        self.gkScene = gkScene
    }

    // MARK: - Camera transitions

    // transition to the specified camera
    // this method will reparent the main camera under the camera named "cameraNamed"
    // and trigger the animation to smoothly move from the current position to the new position
    func insertActiveCamera(into cameraName: String, animationDuration duration: CFTimeInterval = GameController.defaultCameraTransitionDuration) {
        guard let camera = scene?.rootNode.childNode(withName: cameraName, recursively: true) else { return }
        if self.activeCamera == camera {
            return
        }

        self.lastActiveCamera = activeCamera
        if activeCamera != nil {
            self.lastActiveCameraFrontDirection = (activeCamera?.presentation.simdWorldFront)!
        }
        self.activeCamera = camera

        // save old transform in world space
        let oldTransform: SCNMatrix4 = activeCameraNode.presentation.worldTransform

        // re-parent
        camera.addChildNode(activeCameraNode)

        // compute the old transform relative to our new parent node (yeah this is the complex part)
        let parentTransform = camera.presentation.worldTransform
        let parentInv = SCNMatrix4Invert(parentTransform)

        // with this new transform our position is unchanged in workd space (i.e we did re-parent but didn't move).
        activeCameraNode.transform = SCNMatrix4Mult(oldTransform, parentInv)

        // now animate the transform to identity to smoothly move to the new desired position
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        activeCameraNode.transform = SCNMatrix4Identity

        if let cameraTemplate = camera.camera {
            activeCameraNode.camera!.zFar = cameraTemplate.zFar
            activeCameraNode.camera!.zNear = cameraTemplate.zNear
            activeCameraNode.camera!.fieldOfView = cameraTemplate.fieldOfView
            activeCameraNode.camera!.wantsDepthOfField = cameraTemplate.wantsDepthOfField
            activeCameraNode.camera!.sensorHeight = cameraTemplate.sensorHeight
            activeCameraNode.camera!.fStop = cameraTemplate.fStop
            activeCameraNode.camera!.focusDistance = cameraTemplate.focusDistance
            activeCameraNode.camera!.bloomIntensity = cameraTemplate.bloomIntensity
            activeCameraNode.camera!.bloomThreshold = cameraTemplate.bloomThreshold
            activeCameraNode.camera!.bloomBlurRadius = cameraTemplate.bloomBlurRadius
            activeCameraNode.camera!.wantsHDR = cameraTemplate.wantsHDR
            activeCameraNode.camera!.automaticallyAdjustsZRange = cameraTemplate.automaticallyAdjustsZRange
            activeCameraNode.camera!.wantsExposureAdaptation = cameraTemplate.wantsExposureAdaptation
            activeCameraNode.camera!.vignettingPower = cameraTemplate.vignettingPower
            activeCameraNode.camera!.vignettingIntensity = cameraTemplate.vignettingIntensity
        }
        SCNTransaction.commit()
    }

    // MARK: - Audio

    func playSound(_ audioName: AudioSourceKind) {
        scene!.rootNode.addAudioPlayer(SCNAudioPlayer(source: audioSources[audioName.rawValue]))
    }

    func setupAudio() {
        // Get an arbitrary node to attach the sounds to.
        let node = scene!.rootNode

        // ambience
//        if let audioSource = SCNAudioSource(named: "FFXI.scnassets/audio/100-wronfaure.mp3") {
//            audioSource.loops = true
//            audioSource.volume = 0.8
//            audioSource.isPositional = false
//            audioSource.shouldStream = true
//            node.addAudioPlayer(SCNAudioPlayer(source: audioSource))
//        }
        // volcano
        if let volcanoNode = scene!.rootNode.childNode(withName: "particles_volcanoSmoke_v2", recursively: true) {
            if let audioSource = SCNAudioSource(named: "audio/volcano.mp3") {
                audioSource.loops = true
                audioSource.volume = 5.0
                volcanoNode.addAudioPlayer(SCNAudioPlayer(source: audioSource))
            }
        }

        // other sounds
        audioSources[AudioSourceKind.collect.rawValue] = SCNAudioSource(named: "audio/collect.mp3")!
        audioSources[AudioSourceKind.collectBig.rawValue] = SCNAudioSource(named: "audio/collectBig.mp3")!
        audioSources[AudioSourceKind.unlockDoor.rawValue] = SCNAudioSource(named: "audio/unlockTheDoor.m4a")!
        audioSources[AudioSourceKind.hitEnemy.rawValue] = SCNAudioSource(named: "audio/hitEnemy.wav")!

        // adjust volumes
        audioSources[AudioSourceKind.unlockDoor.rawValue].isPositional = false
        audioSources[AudioSourceKind.collect.rawValue].isPositional = false
        audioSources[AudioSourceKind.collectBig.rawValue].isPositional = false
        audioSources[AudioSourceKind.hitEnemy.rawValue].isPositional = false

        audioSources[AudioSourceKind.unlockDoor.rawValue].volume = 0.5
        audioSources[AudioSourceKind.collect.rawValue].volume = 4.0
        audioSources[AudioSourceKind.collectBig.rawValue].volume = 4.0
    }

    // MARK: - Init

    init(sceneRenderer scnView: SCNView, minimapRenderer mmRenderer: SCNView, ffxiClient: FFXIClient) {

        client = ffxiClient

        super.init()

        sceneRenderer = scnView
        sceneRenderer!.delegate = self

        minimapRenderer = mmRenderer
        minimapRenderer?.delegate = self

        // Uncomment to show statistics such as fps and timing information
        scnView.showsStatistics = true
        scnView.debugOptions = []
        // setup overlay

        loadSceneFor(zone: .current)
        configureRenderingQuality(scnView)
    }

    func loadSceneFor(zone: Zone) {
        Task {
            var newScene: SCNScene? {
                SCNScene(named: "ffxi.scn", inDirectory: "FFXI.scnassets")
            }
            let scene = newScene!
            let map = SCNNode()
            let minimap = newScene!
            map.name = zone.nodeName
            let mapCollisionRootNode = zone.collisionScene()!.rootNode
            if let mapScene = zone.scene() {
                if let environment = zone.metadata.environment, let contents = environment.skybox {
                    var con: Any?
                    switch contents {
                    case .cubemap(let a, let b, let c, let d, let e, let f):
                        con = [a, b, c, d, e, f]
                    case .rotatingImage(let string):
                        con = string
                    }
                    scene.background.contents = con
                    scene.lightingEnvironment.contents = con // .useBackground
                } else {
                    scene.background.contents = mapScene.background.contents
                    scene.lightingEnvironment.contents = mapScene.lightingEnvironment.contents
                }
                if let o = zone.metadata.fog?.color { scene.fogColor = o } else { scene.fogColor = NSColor.clear }
                if let o = zone.metadata.fog?.range.lowerBound { scene.fogStartDistance = o } else { scene.fogStartDistance = 0 }
                if let o = zone.metadata.fog?.range.upperBound { scene.fogEndDistance = o } else { scene.fogEndDistance = 0 }
                if let o = zone.metadata.fog?.densityExponent { scene.fogDensityExponent = o } else { scene.fogDensityExponent = 0 }
                map.addChildNode(mapScene.rootNode)
//                minimap.rootNode.addChildNode(map)
                map.addChildNode(mapCollisionRootNode)
                scene.rootNode.addChildNode(map)
            } else {
                assertionFailure("no map loaded for zone: \(zone)")
            }
            await MainActor.run {

                // load the main scene
                self.scene = scene
                // configure quality

                // setup physics and navmesh
                let navigationGraph = GKGraph(
                    mapCollisionRootNode
                        .geometry?
                        .vertices()?
                        .compactMap {
                            GKGraphNode3D(point: SIMD3<Float>($0))
//                            GKGraphNode3D(point: SIMD3<Float>(x: $0.x, y: $0.y, z: $0.z))
                        }
                    ?? []
                )
                self.map = .init(visible: map, collisions: mapCollisionRootNode, navigation: navigationGraph)

                // load the character

                setupCharacter()
                setupEnemies()

                // setup lighting
                directLight = scene.rootNode.childNode(withName: "directLight", recursively: true)

#if !os(macOS)
//                directLight?.castsShadow = false  // turn on cascade shadows
#endif

                // setup camera

                setupCamera()

                // setup game controller

                setupGameController()

                // assign the scene to the view
                sceneRenderer!.scene = self.scene

                minimapRenderer?.scene = self.scene
                minimapRenderer?.pointOfView = minimapCamera
//                minimapRenderer?.scene?.wantsScreenSpaceReflection = false

                // setup audio
                setupAudio()

                // select the point of view to use
                sceneRenderer!.pointOfView = self.activeCamera

                // register ourself as the physics contact delegate to receive contact notifications
                sceneRenderer!.scene!.physicsWorld.contactDelegate = self
            }
        }
    }

    func resetPlayerPosition() {
        character!.queueResetCharacterPosition()
    }

    // MARK: - cinematic

    func startCinematic() {
        playingCinematic = true
        character!.node!.isPaused = true
    }

    func stopCinematic() {
        playingCinematic = false
        character!.node!.isPaused = false
    }

    // MARK: - Controlling the character

    func controllerJump(_ controllerJump: Bool) {
        character!.isJump = controllerJump
    }

    var characterDirection: vector_float2 {
        get {
            return character!.direction
        }
        set {
            var direction = newValue
            let l = simd_length(direction)
            if l > 1.0 {
                direction *= 1 / l
            }
            character!.direction = direction
        }
    }

    var cameraDirection = SIMD2<Float>.zero {
        didSet {
            let l = simd_length(cameraDirection)
            if l > 1.0 {
                cameraDirection *= 1 / l
            }
//            cameraDirection.y = 0
        }
    }

    var cameraDistanceModifier: Float = 1 {
        didSet {
//            guard let follow = activeCameraNode.constraints?.first(where: { $0 is SCNDistanceConstraint }) as? SCNDistanceConstraint else { return }
//            var simdDistance = simd_distance(self.lookAtTarget.simdPosition, activeCameraNode.simdWorldPosition)
////            simdDistance -= (cameraDistanceModifier + abs(cameraDirection.y))
//
//            let distance = CGFloat(simdDistance)
//            let maxD = CGFloat(10)
//            let minD = CGFloat(2)
//            follow.minimumDistance = minD
//            follow.maximumDistance = min(maxD, max(follow.minimumDistance, distance))
        }
    }
//    var cameraFocalLength: Float = 5 {
//        didSet {
//            cameraNode.camera?.focusDistance = CGFloat(cameraFocalLength)
//        }
//    }

    var isAutoMove: Bool = false {
        willSet {
            if characterDirection.allZero() {
                self.isAutoMove = false // not recursive  in Swift 5
            }
        }
    }

    var isMinimapHidden: Bool = true {
        didSet {
            (minimapRenderer as? SCNView)?.allowsCameraControl = !isMinimapHidden
            if isMinimapHidden {
                minimapCamera?.simdWorldPosition = .zero
                minimapCamera?.simdEulerAngles = .zero
            } else {
                minimapRenderer?.pointOfView = minimapCamera
            }
        }
    }

    // MARK: - Update

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let isMinimap = renderer.pointOfView == minimapCamera
        guard !isMinimap else {
            return // do nothing for minimap renderer
        }

        // compute delta time
        if lastUpdateTime == 0 {
            lastUpdateTime = time
        }
        let deltaTime: TimeInterval = time - lastUpdateTime
        lastUpdateTime = time

        // stop here if cinematic
        if playingCinematic == true {
            return
        }

        // update characters
        character?.update(atTime: time, with: renderer)
        #if !OFFLINE
        if time - lastSyncTime >= 0.5, let pos = self.character?.node?.simdPosition {
            lastSyncTime = time
            let rot = Float(self.character!.directionAngle)

            Task.detached(priority: .background) {
                try? await self.client.sync(position: pos, rotation: rot)
            }
        }
        #endif

        // update enemies
        if let entities = gkScene?.entities {
            for entity: GKEntity in entities {
                entity.update(deltaTime: deltaTime)
            }
        }
    }

    struct RenderEnvironment {
        let scene: SCNScene
        let directLight: SCNLight
    }

    struct RenderOptions {

        let wantsScreenSpaceReflection: Bool
//        let backgroundContents: Any?
//        let fogEndDistance: CGFloat
        let maximumShadowDistance: CGFloat

        static let optimized = RenderOptions(
            wantsScreenSpaceReflection: false,
//            backgroundContents: "",
            maximumShadowDistance: 0
//            castsShadow: false
        )

        init(from renderEnvironment: RenderEnvironment) {
            wantsScreenSpaceReflection = renderEnvironment.scene.wantsScreenSpaceReflection
            maximumShadowDistance = renderEnvironment.directLight.maximumShadowDistance
//            backgroundContents = renderEnvironment.scene.background.contents
//            fogEndDistance = renderEnvironment.scene.fogEndDistance
//            castsShadow = renderEnvironment.directLight.castsShadow
        }

        init(wantsScreenSpaceReflection: Bool, maximumShadowDistance: CGFloat) {
            self.wantsScreenSpaceReflection = wantsScreenSpaceReflection
            self.maximumShadowDistance = maximumShadowDistance
//            self.backgroundContents = backgroundContents
//            self.fogEndDistance = fogEndDistance
//            self.castsShadow = castsShadow
        }

        func optimize(renderEnvironment: RenderEnvironment) {
            renderEnvironment.scene.wantsScreenSpaceReflection = Self.optimized.wantsScreenSpaceReflection
            renderEnvironment.directLight.maximumShadowDistance = Self.optimized.maximumShadowDistance
            //            renderEnvironment.scene.fogEndDistance = Self.optimized.fogEndDistance
//            renderEnvironment.scene.background.contents = NSColor.clear
        }

        func restore(renderEnvironment: RenderEnvironment) {
            renderEnvironment.scene.wantsScreenSpaceReflection = wantsScreenSpaceReflection
            renderEnvironment.directLight.maximumShadowDistance = maximumShadowDistance
//            renderEnvironment.directLight.castsShadow = castsShadow
//            renderEnvironment.scene.lightingEnvironment = .init(contents: backgroundContents)
//            renderEnvironment.scene.fogEndDistance = fogEndDistance
//            renderEnvironment.scene.background.contents = backgroundContents
        }
    }

    private var minimapRenderOptionsToRestore: RenderOptions?
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        let isMinimap = renderer.pointOfView == minimapCamera
        guard isMinimap else {
            return // do nothing for normal renderer
        }

        guard let directLight = directLight?.light else {
            return print("wheres the light")
        }

        let re = RenderEnvironment(scene: scene, directLight: directLight)
        if minimapRenderOptionsToRestore == nil {
            minimapRenderOptionsToRestore = .init(from: re)
        }
        minimapRenderOptionsToRestore?.optimize(renderEnvironment: re)
    }

    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        let isMinimap = renderer.pointOfView == minimapCamera
        guard isMinimap, let minimapRenderOptionsToRestore = minimapRenderOptionsToRestore else {
            return // do nothing for normal renderer
        }
//        defer { self.minimapRenderOptionsToRestore = nil }

        guard let directLight = directLight?.light else {
            return print("wheres the light")
        }

        minimapRenderOptionsToRestore.restore(renderEnvironment: .init(scene: scene, directLight: directLight))
    }
    // MARK: - contact delegate

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {

        // triggers e.g. zone lines
//        if contact.nodeA.physicsBody!.categoryBitMask == Bitmask.trigger.rawValue {
//            trigger(contact.nodeA)
//        }
//        if contact.nodeB.physicsBody!.categoryBitMask == Bitmask.trigger.rawValue {
//            trigger(contact.nodeB)
//        }
//
//        // collectables
//        if contact.nodeA.physicsBody!.categoryBitMask == Bitmask.collectable.rawValue {
//            collect(contact.nodeA)
//        }
//        if contact.nodeB.physicsBody!.categoryBitMask == Bitmask.collectable.rawValue {
//            collect(contact.nodeB)
//        }
    }

    // MARK: - Configure rendering quality

    func turnOffEXRForMAterialProperty(property: SCNMaterialProperty) {
        if var propertyPath = property.contents as? NSString {
            if propertyPath.pathExtension == "exr" {
                propertyPath = ((propertyPath.deletingPathExtension as NSString).appendingPathExtension("png")! as NSString)
                property.contents = propertyPath
            }
        }
    }

    func turnOffEXR() {
        self.turnOffEXRForMAterialProperty(property: scene!.background)
        self.turnOffEXRForMAterialProperty(property: scene!.lightingEnvironment)

        scene?.rootNode.enumerateChildNodes { (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let materials = child.geometry?.materials {
                for material in materials {
                    self.turnOffEXRForMAterialProperty(property: material.selfIllumination)
                }
            }
        }
    }

    func turnOffNormalMaps() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let materials = child.geometry?.materials {
                for material in materials {
                    material.normal.contents = SKColor.black
                }
            }
        })
    }

    func turnOffHDR() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            child.camera?.wantsHDR = false
        })
    }

    func turnOffDepthOfField() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            child.camera?.wantsDepthOfField = false
        })
    }

    func turnOffSoftShadows() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let lightSampleCount = child.light?.shadowSampleCount {
                child.light?.shadowSampleCount = min(lightSampleCount, 1)
            }
        })
    }

    func turnOffPostProcess() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let light = child.light {
                light.shadowCascadeCount = 0
                light.shadowMapSize = CGSize(width: 1024, height: 1024)
            }
        })
    }

    func turnOffOverlay() {
        sceneRenderer?.overlaySKScene = nil
    }

    func turnOffVertexShaderModifiers() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if var shaderModifiers = child.geometry?.shaderModifiers {
                shaderModifiers[SCNShaderModifierEntryPoint.geometry] = nil
                child.geometry?.shaderModifiers = shaderModifiers
            }

            if let materials = child.geometry?.materials {
                for material in materials where material.shaderModifiers != nil {
                    var shaderModifiers = material.shaderModifiers!
                    shaderModifiers[SCNShaderModifierEntryPoint.geometry] = nil
                    material.shaderModifiers = shaderModifiers
                }
            }
        })
    }

    func turnOffVegetation() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            guard let materialName = child.geometry?.firstMaterial?.name as NSString? else { return }
            if materialName.contains("_wf") {
                child.isHidden = true
            }
        })
    }

    func configureRenderingQuality(_ view: SCNView) {

#if !os(macOS)
        self.scene?.wantsScreenSpaceReflection = false
#endif

#if os( tvOS )
        self.turnOffEXR()  // tvOS doesn't support exr maps
                           // the following things are done for low power device(s) only
        self.turnOffNormalMaps()
        self.turnOffHDR()
        self.turnOffDepthOfField()
        self.turnOffSoftShadows()
        self.turnOffPostProcess()
        self.turnOffOverlay()
        self.turnOffVertexShaderModifiers()
        self.turnOffVegetation()
#endif

    }

    // MARK: - Debug menu

    func fStopChanged(_ value: CGFloat) {
        sceneRenderer!.pointOfView!.camera!.fStop = value
    }

    func focusDistanceChanged(_ value: CGFloat) {
        sceneRenderer!.pointOfView!.camera!.focusDistance = value
    }

    // MARK: - GameController

    @objc
    func handleControllerDidConnect(_ notification: Notification) {
        if gamePadCurrent != nil {
            return
        }
        guard let gameController = notification.object as? GCController else {
            return
        }
        registerGameController(gameController)
    }

    @objc
    func handleControllerDidDisconnect(_ notification: Notification) {
        guard let gameController = notification.object as? GCController else {
            return
        }
        if gameController != gamePadCurrent {
            return
        }

        unregisterGameController()

        for controller: GCController in GCController.controllers() where gameController != controller {
            registerGameController(controller)
        }
    }

    func registerGameController(_ gameController: GCController) {

        var buttonA: GCControllerButtonInput?
        var buttonB: GCControllerButtonInput?

        if let gamepad = gameController.extendedGamepad {
            self.gamePadLeft = gamepad.leftThumbstick
            self.gamePadRight = gamepad.rightThumbstick
            buttonA = gamepad.buttonA
            buttonB = gamepad.buttonB
        } else if let gamepad = gameController.gamepad {
            self.gamePadLeft = gamepad.dpad
            buttonA = gamepad.buttonA
            buttonB = gamepad.buttonB
        } else if let gamepad = gameController.microGamepad {
            self.gamePadLeft = gamepad.dpad
            buttonA = gamepad.buttonA
            buttonB = gamepad.buttonX
        }

        weak var weakController = self

        gamePadLeft!.valueChangedHandler = {(_ dpad: GCControllerDirectionPad, _ xValue: Float, _ yValue: Float) -> Void in
            guard let strongController = weakController else {
                return
            }
            strongController.characterDirection = simd_make_float2(xValue, -yValue)
        }

        if let gamePadRight = self.gamePadRight {
            gamePadRight.valueChangedHandler = {(_ dpad: GCControllerDirectionPad, _ xValue: Float, _ yValue: Float) -> Void in
                guard let strongController = weakController else {
                    return
                }
                strongController.cameraDirection = simd_make_float2(xValue, yValue)
            }
        }

        buttonA?.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value: Float, _ pressed: Bool) -> Void in
            guard let strongController = weakController else {
                return
            }
            strongController.controllerJump(pressed)
        }

#if os( iOS )
        if gamePadLeft != nil {
//            overlay!.hideVirtualPad()
        }
#endif
    }

    func unregisterGameController() {
        gamePadLeft = nil
        gamePadRight = nil
        gamePadCurrent = nil
#if os( iOS )
        overlay!.showVirtualPad()
#endif
    }

#if os( iOS )
    // MARK: - PadOverlayDelegate

    func padOverlayVirtualStickInteractionDidStart(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = float2(Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
        }
        if padNode == overlay!.controlOverlay!.rightPad {
            cameraDirection = float2( -Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
        }
    }

    func padOverlayVirtualStickInteractionDidChange(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = float2(Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
        }
        if padNode == overlay!.controlOverlay!.rightPad {
            cameraDirection = float2( -Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
        }
    }

    func padOverlayVirtualStickInteractionDidEnd(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = [0, 0]
        }
        if padNode == overlay!.controlOverlay!.rightPad {
            cameraDirection = [0, 0]
        }
    }

    func willPress(_ button: ButtonOverlay) {
        if button == overlay!.controlOverlay!.buttonA {
            controllerJump(true)
        }
        if button == overlay!.controlOverlay!.buttonB {
            controllerAttack()
        }
    }

    func didPress(_ button: ButtonOverlay) {
        if button == overlay!.controlOverlay!.buttonA {
            controllerJump(false)
        }
    }
#endif
}
