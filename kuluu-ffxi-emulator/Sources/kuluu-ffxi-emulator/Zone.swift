//
//  Zone.swift
//  kuluu
//
//  Created by jon on 6/6/22.
//

import Foundation
import Accessibility

/// Cross-platform color
/// clients of this library should write extensions to convert to their native color type
public struct XColor {
    public let a: Double
    public let r: Double
    public let g: Double
    public let b: Double
}

public struct Fog {
    public let color: XColor
    public let range: Range<CGFloat>
    public let densityExponent: CGFloat
}

public struct ZoneEnvironment {
    public enum SkyboxType {
        case cubemap(a: Any, b: Any, c: Any, d: Any, e: Any, f: Any),
             rotatingImage(String)

        public init(cubemapImage: Any) {
            self = .cubemap(a: cubemapImage, b: cubemapImage, c: cubemapImage, d: cubemapImage, e: cubemapImage, f: cubemapImage)
        }
    }

    public let skybox: SkyboxType?
    public let atmosphere: String?
}

public protocol ZoneMetadata {
    var id: Int { get }
    var lines: [ZoneLine] { get }
    var fog: Fog? { get }
    var environment: ZoneEnvironment? { get }
}

public enum Zone: Int {
    public static var current: Zone = Self.valkurmDunes
    case ssandoria = 80
    case wronfaure = 100
    case valkurmDunes = 103
//    case ssandoriaShadow = 230

    public var metadata: ZoneMetadata {
        switch self {
        case .ssandoria: return SSandoria()
        case .wronfaure: return WRonfaure()
        case .valkurmDunes: return ValkurmDunes()
        }
    }

    public var spawnPoint: SIMD3<Float>? {
        metadata.lines.first?.position
    }

    public var nodeName: String {
        "\(rawValue)"
    }
}

public struct ZoneLine {
    let name: String
    let position: SIMD3<Float>
    let rotation: SIMD3<Float>
    let scale: SIMD3<Float>
}

public struct SSandoria: ZoneMetadata {
    public let id = Zone.ssandoria.rawValue
    public let lines: [ZoneLine] = [
        .init(
            name: "z6e2z2s1",
            position: .init(x: -113.372, y: 4.07481, z: -57.4183),
            rotation: .init(x: 0, y: 0.7853982, z: 0),
            scale: .init(x: 15, y: 10, z: 2)
        )
    ]
    public let fog: Fog? = nil
    public let environment: ZoneEnvironment? = .init(skybox: nil, atmosphere: nil)
}

public struct WRonfaure: ZoneMetadata {
    public let id = Zone.wronfaure.rawValue
    public let lines: [ZoneLine] = [
        .init(
            name: "",
            position: .init(x: 125.88, y: 64.6373, z: 274.1),
            rotation: .init(x: 0, y: 2.3561945, z: 0),
            scale: .init(x: 3, y: 5, z: 10)
        )
    ]
    public let fog: Fog? = nil
    public let environment: ZoneEnvironment? = .init(skybox: nil, atmosphere: nil)
}

public struct ValkurmDunes: ZoneMetadata {
    public let id = Zone.valkurmDunes.rawValue
    public let lines: [ZoneLine] = [
        .init(
            name: "selbina",
            position: .init(x: 58, y: 4.5, z: 166),
            rotation: .init(x: 0, y: 0, z: 0),
            scale: .init(x: 32, y: 10, z: 2)
        )
    ]
    public var fog: Fog?

    public var environment: ZoneEnvironment? {
        return .init(
            skybox: .init(cubemapImage: "FFXI.scnassets/noesisv4464/dust    suny_c01.png"),
//            skybox: .rotatingImage("f"),
            atmosphere: nil
        )
    }
}
