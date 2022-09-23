//
//  ResidentialArea4.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct ResidentialArea4: ZoneSceneMetadata {
        public let id = Zone.residentialArea4.rawValue
        public let name = "Residential_Area4"
        public let lines: [ZoneLine] = [
            .init(
                name: "z4l0z4i3",
                position: .init(x: 117.11819, y: -8.71214, z: 0.00661037),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 2.0, y: 6.0, z: 6.0)
            ),
            .init(
                name: "z4l1",
                position: .init(x: 114.30756, y: -7.639169, z: 0.022039935),
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