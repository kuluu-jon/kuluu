//
//  GustavTunnel.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct GustavTunnel: ZoneSceneMetadata {
        public let id = Zone.gustavTunnel.rawValue
        public let name = "Gustav Tunnel"
        public let lines: [ZoneLine] = [
            .init(
                name: "z4r0z2j7",
                position: .init(x: 380.064, y: -35.3323, z: 6.945321),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 12.0, y: 8.0, z: 2.0)
            ),
            .init(
                name: "z4r1",
                position: .init(x: 380.61725, y: -34.61046, z: 4.5811896),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.0, y: 3.0, z: 4.0)
            ),
            .init(
                name: "z4r2z2j9",
                position: .init(x: 87.46854, y: -3.5898285, z: 380.54514),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 12.0, y: 8.0, z: 2.0)
            ),
            .init(
                name: "z4r3",
                position: .init(x: 84.74062, y: -2.4710696, z: 379.57416),
                rotation: .init(x: 0.0, y: 3.1415927, z: 0.0),
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