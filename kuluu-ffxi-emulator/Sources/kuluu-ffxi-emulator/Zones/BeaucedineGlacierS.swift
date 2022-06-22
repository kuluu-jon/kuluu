//
//  BeaucedineGlacierS.swift
//
//  Auto-generated by `zone-metadata-generator` on 6/21/22
//
public struct BeaucedineGlacierS: ZoneSceneMetadata {
    public let id = Zone.beaucedineGlacierS.rawValue
    public let lines: [ZoneLine] = [
        .init(
            name: "z0s0z0p7",
            position: .init(x: -220.08249, y: -19.67884, z: 84.99095),
            rotation: .init(x: 0.0, y: 0.0, z: 0.0),
            scale: .init(x: 10.0, y: 8.0, z: 1.0)
        ),
        .init(
            name: "z0s1",
            position: .init(x: -219.99564, y: -18.586657, z: 82.795494),
            rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
            scale: .init(x: 1.0, y: 5.0, z: 5.0)
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