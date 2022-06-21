// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "kuluu-ffxi-network-protocol",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "kuluu-ffxi-network-protocol",
            targets: ["kuluu-ffxi-network-protocol"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.4"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.5.1"),
        .package(url: "https://github.com/jverkoey/BinaryCodable.git", from: "0.3.1"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "kuluu-ffxi-network-protocol",
            dependencies: [
                "CocoaAsyncSocket",
                "CryptoSwift",
                "BinaryCodable",
                "CollectionConcurrencyKit"
            ]
        ),
        .testTarget(
            name: "kuluu-ffxi-network-protocolTests",
            dependencies: ["kuluu-ffxi-network-protocol"]
        )
    ]
)
