//
//  Beadeaux.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct Beadeaux: ZoneSceneMetadata {
        public let id = Zone.beadeaux.rawValue
        public let name = "Beadeaux"
        public let lines: [ZoneLine] = [
            .init(
                name: "z0m0z0n1",
                position: .init(x: -140.0, y: -2.17448, z: -59.925842),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.0, y: 5.0, z: 8.0)
            ),
            .init(
                name: "z0m1",
                position: .init(x: -140.0, y: -2.10038, z: -56.89304),
                rotation: .init(x: 0.0, y: 4.712389, z: 0.0),
                scale: .init(x: 1.0, y: 4.0, z: 5.0)
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