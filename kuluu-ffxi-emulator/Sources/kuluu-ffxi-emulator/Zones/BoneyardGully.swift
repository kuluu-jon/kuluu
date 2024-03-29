//
//  BoneyardGully.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct BoneyardGully: ZoneSceneMetadata {
        public let id = Zone.boneyardGully.rawValue
        public let name = "Boneyard Gully"
        public let lines: [ZoneLine] = [
            .init(
                name: "z2k0z2i5",
                position: .init(x: -300.0879, y: -1.0846355, z: 96.04378),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 2.0, y: 8.0, z: 15.0)
            ),
            .init(
                name: "z2k1",
                position: .init(x: -297.10928, y: 0.008156989, z: 96.00218),
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