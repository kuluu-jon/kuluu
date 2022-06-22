//
//  PromyvionHolla.swift
//
//  Auto-generated by `zone-metadata-generator` on 6/22/22
//
public extension Zone {
    struct PromyvionHolla: ZoneSceneMetadata {
        public let id = Zone.promyvionHolla.rawValue
        public let lines: [ZoneLine] = [
            .init(
                name: "z040z3a9",
                position: .init(x: 673.80304, y: -24.868656, z: 911.89886),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 2.0, y: 10.0, z: 12.0)
            ),
            .init(
                name: "z041",
                position: .init(x: 669.9167, y: -23.137611, z: 911.65466),
                rotation: .init(x: 0.0, y: 2.9670596, z: 0.0),
                scale: .init(x: 1.5, y: 4.0, z: 4.0)
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