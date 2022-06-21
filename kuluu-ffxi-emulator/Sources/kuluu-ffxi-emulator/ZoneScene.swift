//
//  File.swift
//  
//
//  Created by jon on 6/21/22.
//

import Foundation

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

public struct ZoneLine {
    let name: String
    let position: SIMD3<Float>
    let rotation: SIMD3<Float>
    let scale: SIMD3<Float>
}

public protocol ZoneSceneMetadata {
    var id: Int { get }
    var lines: [ZoneLine] { get } // TODO: remove, use `ZoneMetadata`
    var fog: Fog? { get }
    var environment: ZoneEnvironment? { get }
}
