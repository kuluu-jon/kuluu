//
//  KuftalTunnel.swift
//
//  Auto-generated by `zone-metadata-generator` on 6/22/22
//
public extension Zone {
    struct KuftalTunnel: ZoneSceneMetadata {
        public let id = Zone.kuftalTunnel.rawValue
        public let lines: [ZoneLine] = [
            .init(
                name: "z2n0z2m1",
                position: .init(x: 320.00952, y: -8.221529, z: -48.071106),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 10.0, y: 10.0, z: 2.0)
            ),
            .init(
                name: "z2n1",
                position: .init(x: 320.0181, y: -6.6841784, z: -45.165775),
                rotation: .init(x: 0.0, y: 4.712389, z: 0.0),
                scale: .init(x: 1.0, y: 5.0, z: 5.0)
            ),
            .init(
                name: "z2n2z2o1",
                position: .init(x: 118.93585, y: -27.622555, z: 648.8407),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 20.0, y: 10.0, z: 2.0)
            ),
            .init(
                name: "z2n3",
                position: .init(x: 120.0, y: -26.000654, z: 640.0),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.0, y: 4.0, z: 7.0)
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