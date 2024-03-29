//
//  PhanauetChannel.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct PhanauetChannel: ZoneSceneMetadata {
        public let id = Zone.phanauetChannel.rawValue
        public let name = "Phanauet Channel"
        public let lines: [ZoneLine] = [
            .init(
                name: "z2r0z2pb",
                position: .init(x: -242.00217, y: -3.9553611, z: -20.019106),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 1.0, y: 10.0, z: 15.0)
            ),
            .init(
                name: "z2r1",
                position: .init(x: -239.44745, y: -1.813427, z: -19.98049),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 1.0, y: 4.0, z: 4.0)
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