//
//  WindurstWoods.swift
//
//  Auto-generated by `zone-metadata-generator` on 9/22/22
//
public extension Zone {
    struct WindurstWoods: ZoneSceneMetadata {
        public let id = Zone.windurstWoods.rawValue
        public let name = "Windurst Woods"
        public let lines: [ZoneLine] = [
            .init(
                name: "z410z379",
                position: .init(x: -100.85721, y: -4.5338774, z: 411.40952),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
                scale: .init(x: 20.0, y: 10.0, z: 3.0)
            ),
            .init(
                name: "z411",
                position: .init(x: -100.05, y: -2.6637714, z: 406.818),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 1.0, y: 4.0, z: 4.0)
            ),
            .init(
                name: "z412z421",
                position: .init(x: -139.99875, y: -7.531558, z: -300.32852),
                rotation: .init(x: 0.0, y: 1.5707964, z: 0.0),
                scale: .init(x: 20.0, y: 10.0, z: 3.0)
            ),
            .init(
                name: "z413",
                position: .init(x: -135.90369, y: -5.788453, z: -300.66846),
                rotation: .init(x: 0.0, y: 0.0, z: 0.0),
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