//
//  SpireOfMea.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct SpireOfMea: ZoneSceneMetadata {
        public let id = Zone.spireOfMea.rawValue
        public let name = "Spire of Mea"
        public let lines: [ZoneLine] = [
            .init(
                name: "z280z291",
                position: .init(x: 113.458, y: -4.0788813, z: -57.3508),
                rotation: .init(x: 0.0, y: 2.3561945, z: 0.0),
                scale: .init(x: 15.0, y: 10.0, z: 2.0)
            ),
            .init(
                name: "z281",
                position: .init(x: 103.97822, y: -1.000004, z: -47.951157),
                rotation: .init(x: 0.0, y: 3.9269907, z: 0.0),
                scale: .init(x: 1.0, y: 4.0, z: 5.0)
            ),
            .init(
                name: "zms0zms1",
                position: .init(x: 164.93318, y: -5.5468006, z: 164.79182),
                rotation: .init(x: 0.0, y: 3.926991, z: 0.0),
                scale: .init(x: 12.0, y: 8.0, z: 2.0)
            ),
            .init(
                name: "zms1",
                position: .init(x: 162.59119, y: -4.1026587, z: 162.42282),
                rotation: .init(x: 0.0, y: 2.3561945, z: 0.0),
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