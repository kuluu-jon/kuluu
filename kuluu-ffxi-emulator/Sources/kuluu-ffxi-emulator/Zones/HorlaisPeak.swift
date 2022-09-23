//
//  HorlaisPeak.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct HorlaisPeak: ZoneSceneMetadata {
        public let id = Zone.horlaisPeak.rawValue
        public let name = "Horlais Peak"
        public let lines: [ZoneLine] = [
            .init(
                name: "z6l0z6j7",
                position: .init(x: -6.1745934, y: -2.9660647, z: -0.008468509),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 2.0, y: 8.0, z: 10.0)
            ),
            .init(
                name: "z6l1",
                position: .init(x: -9.168408, y: -1.5949211, z: 0.001351349),
                rotation: .init(x: 0.0, y: 3.1415927, z: 0.0),
                scale: .init(x: 1.0, y: 3.0, z: 3.0)
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