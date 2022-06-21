// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "kuluu-ffxi-emulator",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "kuluu-ffxi-emulator",
            targets: ["kuluu-ffxi-emulator"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", branch: "main"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.14.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "kuluu-ffxi-emulator",
            dependencies: [
                "CollectionConcurrencyKit",
                "Stencil"
            ]),
        .testTarget(
            name: "kuluu-ffxi-emulatorTests",
            dependencies: ["kuluu-ffxi-emulator"]),
    ]
)
