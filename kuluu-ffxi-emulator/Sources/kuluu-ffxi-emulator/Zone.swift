public enum Zone: Int, CaseIterable {
    public static var current: Zone = Self.allCases.first!
    case tavnazianSafehold = 26
    case temenos = 37
    case beadeauxS = 92
    case rolanberryFields = 110
    case capeTeriggan = 113
    case yughottGrotto = 142
    case ranguemontPass = 166

    public var metadata: ZoneSceneMetadata {
        switch self {
        case .tavnazianSafehold: return TavnazianSafehold()
        case .temenos: return Temenos()
        case .beadeauxS: return BeadeauxS()
        case .rolanberryFields: return RolanberryFields()
        case .capeTeriggan: return CapeTeriggan()
        case .yughottGrotto: return YughottGrotto()
        case .ranguemontPass: return RanguemontPass()

        }
    }
    
    public var spawnPoint: SIMD3<Float>? {
        metadata.lines.first?.position
    }
    
    public var nodeName: String {
        .init(rawValue)
    }
}