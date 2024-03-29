//
//  PalboroughMines.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct PalboroughMines: ZoneSceneMetadata {
        public let id = Zone.palboroughMines.rawValue
        public let name = "Palborough Mines"
        public let lines: [ZoneLine] = [
            .init(
                name: "z6h3",
                position: .init(x: 14.871813, y: 8.918405, z: 24.002274),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 1.0, y: 3.0, z: 3.0)
            ),
            .init(
                name: "z6h2z4n1",
                position: .init(x: 12.494564, y: 6.9738774, z: 24.046854),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 8.0, y: 8.0, z: 2.0)
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