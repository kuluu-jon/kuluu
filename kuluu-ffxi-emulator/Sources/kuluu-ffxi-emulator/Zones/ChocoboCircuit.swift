//
//  ChocoboCircuit.swift
//
//  Auto-generated by `zone-metadata-generator` on 6/22/22
//
public extension Zone {
    struct ChocoboCircuit: ZoneSceneMetadata {
        public let id = Zone.chocoboCircuit.rawValue
        public let lines: [ZoneLine] = [
            .init(
                name: "z400z3z3",
                position: .init(x: -364.0058, y: 101.223656, z: -259.9546),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 2.0, y: 8.0, z: 12.0)
            ),
            .init(
                name: "z401",
                position: .init(x: -361.43375, y: 101.79805, z: -259.99567),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 1.0, y: 4.0, z: 4.0)
            ),
            .init(
                name: "z402z3z5",
                position: .init(x: 340.00394, y: -118.80647, z: 280.00223),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 2.0, y: 8.0, z: 12.0)
            ),
            .init(
                name: "z403",
                position: .init(x: 340.01657, y: -118.1067, z: 277.48395),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
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