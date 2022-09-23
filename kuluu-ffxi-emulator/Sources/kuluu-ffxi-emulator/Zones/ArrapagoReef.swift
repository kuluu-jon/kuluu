//
//  ArrapagoReef.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct ArrapagoReef: ZoneSceneMetadata {
        public let id = Zone.arrapagoReef.rawValue
        public let name = "Arrapago Reef"
        public let lines: [ZoneLine] = [
            .init(
                name: "z1e0z1c5",
                position: .init(x: -158.10202, y: 1.71772e-07, z: 0.0053858384),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 1.5, y: 10.0, z: 12.0)
            ),
            .init(
                name: "z1e1",
                position: .init(x: -155.85431, y: 0.22541964, z: -0.004226785),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 1.0, y: 3.0, z: 4.0)
            ),
            .init(
                name: "zmryzmrx",
                position: .init(x: -114.0, y: -3.3327222, z: -80.0),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 1.5, y: 10.0, z: 12.0)
            ),
            .init(
                name: "zmrx",
                position: .init(x: -102.5, y: -1.5, z: -80.0),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 1.0, y: 3.0, z: 4.0)
            ),
        ]
        public var fog: Fog?
        public var environment: ZoneEnvironment? {
            return .init(
                skybox: nil,
                atmosphere: nil
            )
        }
    }
}