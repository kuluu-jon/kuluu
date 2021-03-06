//
//  AlZahbi.swift
//
//  Auto-generated by `zone-metadata-generator` on 6/21/22
//
public struct AlZahbi: ZoneSceneMetadata {
    public let id = Zone.alZahbi.rawValue
    public let lines: [ZoneLine] = [
        .init(
            name: "z4c0z4b3",
            position: .init(x: 117.11819, y: -8.71214, z: 0.00661037),
            rotation: .init(x: 0.0, y: 0.0, z: 0.0),
            scale: .init(x: 2.0, y: 6.0, z: 6.0)
        ),
        .init(
            name: "z4c1",
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