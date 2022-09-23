//
//  HallOfTheGods.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct HallOfTheGods: ZoneSceneMetadata {
        public let id = Zone.hallOfTheGods.rawValue
        public let name = "Hall of the Gods"
        public let lines: [ZoneLine] = [
            .init(
                name: "z3s2z3t1",
                position: .init(x: -180.0, y: -86.8931, z: 283.0),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 2.0, y: 16.0, z: 18.0)
            ),
            .init(
                name: "z3s3",
                position: .init(x: -180.0, y: -81.850006, z: 280.0),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.0, y: 4.0, z: 4.0)
            ),
            .init(
                name: "z3s0z2c5",
                position: .init(x: 18.084078, y: -4.2975936, z: -658.11993),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 2.0, y: 10.0, z: 14.0)
            ),
            .init(
                name: "z3s1",
                position: .init(x: 17.331057, y: -2.812844, z: -654.23016),
                rotation: .init(x: 0.0, y: 4.712389, z: 0.0),
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