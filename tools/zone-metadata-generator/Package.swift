// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "zone-metadata-generator",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "zone-metadata-generator",
            targets: ["zone-metadata-generator"]),
    ],
    dependencies: [
        .package(name: "kuluu-ffxi-emulator", path: "../kuluu-ffxi-emulator"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.14.1"),
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.13.1"),
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "zone-metadata-generator",
            dependencies: [
                "kuluu-ffxi-emulator",
                "Stencil",
                "XMLCoder",
                "CollectionConcurrencyKit",
            ],
            resources: [.copy("Data")]
        ),
        .testTarget(
            name: "zone-metadata-generatorTests",
            dependencies: ["zone-metadata-generator"]
        ),
    ]
)
