//
//  ZhayolmRemnants.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct ZhayolmRemnants: ZoneSceneMetadata {
        public let id = Zone.zhayolmRemnants.rawValue
        public let name = "Zhayolm Remnants"
        public let lines: [ZoneLine] = [
            .init(
                name: "z0x0z0y1",
                position: .init(x: 0.068177834, y: -13.285759, z: -439.24677),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.5, y: 10.0, z: 15.0)
            ),
            .init(
                name: "z0x1",
                position: .init(x: 0.0, y: -12.5, z: -464.781),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.5, y: 5.0, z: 6.0)
            ),
            .init(
                name: "z0x2z111",
                position: .init(x: 0.0, y: 0.0653028, z: 723.119),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 2.0, y: 10.0, z: 20.0)
            ),
            .init(
                name: "z0x3",
                position: .init(x: 0.0, y: 0.0785, z: 718.1124),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.5, y: 6.0, z: 8.0)
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