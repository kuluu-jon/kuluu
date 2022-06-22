//
//  CloisterOfTides.swift
//
//  Auto-generated by `zone-metadata-generator` on 6/22/22
//
public extension Zone {
    struct CloisterOfTides: ZoneSceneMetadata {
        public let id = Zone.cloisterOfTides.rawValue
        public let lines: [ZoneLine] = [
            .init(
                name: "z6w0z2v5",
                position: .init(x: 16.894743, y: -19.332808, z: 104.28425),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 20.0, y: 10.0, z: 3.0)
            ),
            .init(
                name: "z6w1",
                position: .init(x: 17.981033, y: -16.806072, z: 99.829544),
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