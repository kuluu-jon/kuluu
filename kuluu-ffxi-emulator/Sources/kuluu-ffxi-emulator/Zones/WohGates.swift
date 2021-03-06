//
//  WohGates.swift
//
//  Auto-generated by `zone-metadata-generator` on 6/21/22
//
public struct WohGates: ZoneSceneMetadata {
    public let id = Zone.wohGates.rawValue
    public let lines: [ZoneLine] = [
        .init(
            name: "z0j0z0i1",
            position: .init(x: -0.012528807, y: -4.10515, z: 296.02402),
            rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
            scale: .init(x: 1.0, y: 5.0, z: 11.0)
        ),
        .init(
            name: "z0j1",
            position: .init(x: -0.0392012, y: -4.083493, z: 293.641),
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