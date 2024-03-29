//
//  AbysseaAltepa.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct AbysseaAltepa: ZoneSceneMetadata {
        public let id = Zone.abysseaAltepa.rawValue
        public let name = "Abyssea - Altepa"
        public let lines: [ZoneLine] = [
            .init(
                name: "z4m0z2tb",
                position: .init(x: -140.0437, y: 4.7546408e-07, z: -324.57013),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 3.0, y: 10.0, z: 20.0)
            ),
            .init(
                name: "z4m1",
                position: .init(x: -139.98619, y: 2.1624055, z: -321.5076),
                rotation: .init(x: 0.0, y: 4.712389, z: 0.0),
                scale: .init(x: 1.0, y: 3.0, z: 5.0)
            ),
            .init(
                name: "z4m2z331",
                position: .init(x: 305.88525, y: -70.47017, z: 258.02194),
                rotation: .init(x: 0.0, y: 3.1415927, z: 0.0),
                scale: .init(x: 3.0, y: 10.0, z: 20.0)
            ),
            .init(
                name: "z4m3",
                position: .init(x: 302.77832, y: -68.13107, z: 257.7589),
                rotation: .init(x: 0.0, y: 3.1415927, z: 0.0),
                scale: .init(x: 1.0, y: 3.0, z: 5.0)
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