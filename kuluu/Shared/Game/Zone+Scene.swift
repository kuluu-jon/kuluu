//
//  Zone+Scene.swift
//  kuluu
//
//  Created by jon on 6/11/22.
//

import SceneKit
import kuluu_ffxi_emulator

extension Zone {

    func scenePath(extension: String) -> String {
        // TODO: R.swiftify
        "FFXI.scnassets/zones/\(rawValue).\(`extension`)"
    }

    func scene() -> SCNScene? {
        SCNScene(named: scenePath(extension: "scn")) ?? SCNScene(named: scenePath(extension: "dae"))
    }

    func collisionScene() -> SCNScene? {

        let directory = "FFXI.scnassets/zones/collisions/"
        func collisionScenePath(extension: String) -> String {
            // TODO: R.swiftify
            "\(rawValue).\(`extension`)"
        }
        return SCNScene(
            named: collisionScenePath(extension: "scn"),
            inDirectory: directory,
            options: [.preserveOriginalTopology: true]
        ) ?? SCNScene(
            named: collisionScenePath(extension: "obj"),
            inDirectory: directory,
            options: [.preserveOriginalTopology: true]
        )
    }
}
