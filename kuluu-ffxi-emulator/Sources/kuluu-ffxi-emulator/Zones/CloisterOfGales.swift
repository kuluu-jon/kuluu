//
//  CloisterOfGales.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct CloisterOfGales: ZoneSceneMetadata {
        public let id = Zone.cloisterOfGales.rawValue
        public let name = "Cloister of Gales"
        public let lines: [ZoneLine] = [
            .init(
                name: "z510z4yf",
                position: .init(x: -700.9818, y: -9.674457, z: -32.345047),
                rotation: .init(x: 0.0, y: 3.1415927, z: 0.0),
                scale: .init(x: 2.0, y: 10.0, z: 10.0)
            ),
            .init(
                name: "z511",
                position: .init(x: -697.11365, y: -6.655683, z: -32.351017),
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