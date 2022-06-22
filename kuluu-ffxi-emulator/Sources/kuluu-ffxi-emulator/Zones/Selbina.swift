//
//  Selbina.swift
//
//  Auto-generated by `zone-metadata-generator` on 6/22/22
//
public extension Zone {
    struct Selbina: ZoneSceneMetadata {
        public let id = Zone.selbina.rawValue
        public let lines: [ZoneLine] = [
            .init(
                name: "z0a0zi9h",
                position: .init(x: -300.0, y: -4.0751925, z: -215.25),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 2.0, y: 8.0, z: 12.0)
            ),
            .init(
                name: "z0a1",
                position: .init(x: -300.0, y: -1.5000029, z: -219.92845),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.0, y: 3.0, z: 4.0)
            ),
            .init(
                name: "z0a2zi9j",
                position: .init(x: -180.0196, y: -0.3359842, z: -291.25043),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 2.0, y: 8.0, z: 12.0)
            ),
            .init(
                name: "z0a3",
                position: .init(x: -179.68318, y: 2.249997, z: -296.61032),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
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