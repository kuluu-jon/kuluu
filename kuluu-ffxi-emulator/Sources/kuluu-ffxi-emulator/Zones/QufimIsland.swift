//
//  QufimIsland.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct QufimIsland: ZoneSceneMetadata {
        public let id = Zone.qufimIsland.rawValue
        public let name = "Qufim Island"
        public let lines: [ZoneLine] = [
            .init(
                name: "z6x0z3a3",
                position: .init(x: -0.17860928, y: -8.549365, z: 121.01522),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 20.0, y: 10.0, z: 2.0)
            ),
            .init(
                name: "z6x1",
                position: .init(x: 0.0025547445, y: -6.252337, z: 117.971085),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
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